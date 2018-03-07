---
layout: post
title: Verifying SSL Connections to Amazon S3 in CentOS 6 via Ruby
date: 2015-06-10
permalink: /article/verifying-ssl-connections-to-amazon-s3-in-centos-6-via-ruby
---

Whilst building a development virtual machine to distribute to my colleagues I ran into a problem when using the Bundler gem in Ruby. Bundler is a dependency manager and so makes lots of HTTP requests to fetch the necessary Ruby gems and I found that `bundle install` commands kept failing with an SSL error:

     OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

I was using the latest Ruby version, installed via the latest version of RVM (the Ruby version manager) and the latest version of CentOS 6 but no matter what I did I couldn't stop it from blowing up at some point during the installation of loads of gems.

After much time spent banging my head against all of these moving parts I found that it consistently failed on a particular line in the Ruby HTTP library when making an SSL connection to an Amazon S3 endpoint (lots of gems are stored on S3). Being able to reproduce the problem offered some small comfort; SSL isn't something I'm an expert on but at least I knew where to start digging.

    2.1.4 :001 > require 'net/http'
     => true 
    2.1.4 :002 > Net::HTTP.get(URI.parse('https://s3.amazonaws.com'))
    OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:920:in `connect'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:920:in `block in connect'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/timeout.rb:76:in `timeout'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:920:in `connect'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:863:in `do_start'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:852:in `start'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:583:in `start'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:478:in `get_response'
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/lib/ruby/2.1.0/net/http.rb:455:in `get'
            from (irb):4
            from /home/vagrant/.rvm/rubies/ruby-2.1.4/bin/irb:11:in `<main>'

A great tool from Mislav Marohnić ([mislav](https://github.com/mislav) on Github) - [`doctor.rb`](https://raw.githubusercontent.com/mislav/ssl-tools/master/doctor.rb) - told me that the CA (certificate authority) certificate couldn't be verified:

    $ ruby doctor.rb s3.amazonaws.com
    /home/vagrant/.rvm/rubies/ruby-2.1.4/bin/ruby (2.1.4-p265)
    OpenSSL 1.0.1e 11 Feb 2013: /etc/pki/tls
    SSL_CERT_DIR=""
    SSL_CERT_FILE=""

    HEAD https://s3.amazonaws.com:443
    OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

    The server presented a certificate that could not be verified:
      subject: /C=US/O=VeriSign, Inc./OU=VeriSign Trust Network/OU=(c) 2006 VeriSign, Inc. - For authorized use only/CN=VeriSign Class 3 Public Primary Certification Authority - G5
      issuer: /C=US/O=VeriSign, Inc./OU=Class 3 Public Primary Certification Authority
      error code 20: unable to get local issuer certificate

So it would seem that this isn't a problem in Ruby at all but a more general SSL error. A quick check with OpenSSL shows us that the verification does indeed return an error code of `20`:

    $ openssl s_client -host s3.amazonaws.com -port 443
    ...
    Verify return code: 20 (unable to get local issuer certificate)
    ...

I'm sure we're all intimately familiar with the verification return codes within OpenSSL, but for those who aren't a quick check of the `man` page confirms that the certificate can't be verified:

    $ man verify
    ...
    20 X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY: unable to get local issuer certificate
    the issuer certificate could not be found: this occurs if the issuer certificate of an untrusted certificate cannot be found.
    ...

OK, so we can now see that it's a Verisign certificate with the organisational unit "Class 3 Public Primary Certification Authority" that can't be verified. This opened up a whole new avenue in my investigation.

A popular search engine turned up this [page from the cURL mailing list](http://curl.haxx.se/mail/archive-2014-10/0062.html). Dated from the end of October 2014, it says that two Verisign Class 3 Public Primary Certification Authority certificates were dropped from the cURL CA bundle. It also mentions that, "removing that cert from the ca-bundle breaks [connections to] https://s3.amazonaws.com and https://amazon.com". That sounded like the very same problem that I was experiencing via Bundler...

Unsurprisingly my next thought was how I could get these certificates back into my CA bundle and successfully verify connections to Amazon. Fortunately this helpful article, entitled [Adding trusted root certificates to the server](http://kb.kerio.com/product/kerio-connect/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html), described the process I was after.

Taking the two missing certificates directly from the post on the cURL mailing list and cleaning up the patch markings, I put them both in a file at `/etc/pki/ca-trust/source/anchors/verisign.crt`, then ran:

    $ sudo update-ca-trust enable
    $ sudo update-ca-trust extract

Et voilà! We now successfully verify SSL connections to S3: `ruby -r 'net/http' -e "Net::HTTP.get(URI.parse('https://s3.amazonaws.com'))"` (that command doesn't output anything but the important thing is that it doesn't raise an exception...)

To aid fixing this in the future I've put together a shell script to perform all the necessary steps - find it in [this gist](https://gist.github.com/grahamlyons/fa36fe35e798e5cf7ae3). The shell script itself, [verisign_certs.sh](https://gist.githubusercontent.com/grahamlyons/fa36fe35e798e5cf7ae3/raw/b86a31375fa9075730386bb7f25bf983e845d0f3/verisign_certs.sh), can be downloaded and run, as the root user, with `sudo sh ./verisign_certs.sh` (if your CA bundle has changed since installing the `ca-certificates` RPM then you can add the `--force` flag to the script, so long as you're happy to do so).

(I won't advise downloading the script with `curl` and piping it straight into `sh`, lest I end up on [http://curlpipesh.tumblr.com/](http://curlpipesh.tumblr.com/)...)
