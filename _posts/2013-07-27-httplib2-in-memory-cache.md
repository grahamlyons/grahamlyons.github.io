title: A Simple In-Memory Cache for Python's Httplib2
date: 2013-07-27
url_code: a-simple-in-memory-cache-for-python-s-httplib2

When making HTTP requests programmatically it's always nice to have a transparent caching mechanism to make things more efficient when you start fetching the same resource thousands of times a second. I was very close to implementing one with Python's ```httplib``` or ```urllib``` libraries when I came across exactly the functionality I needed in [```httplib2```](https://code.google.com/p/httplib2/). Huzzah! No need to write (and maintain) anything myself - it's all taken care of by a robust, widely used library.

The first argument to the [```Http``` constructor function](http://httplib2.googlecode.com/hg/doc/html/libhttplib2.html#httplib2.Http) is the cache, which must be:
> _either the name of a directory to be used as a flat file cache, or it must an object that implements the required caching interface_

Passing a string as a directory works fine but my instinct is not to use the disk for caching and go for memory whenever possible. Of course that's not going to persist once the process has died but for long-running processes (like a server) it'll be more performant (it wasn't really a worry in my particular instance but it's always good to think about) and won't leave any file/directory detritus lying around on the disk. To that end I wondered how tricky it would be to get myself an object implementing the required caching interface...

The documentation for the [cache objects](http://httplib2.googlecode.com/hg/doc/html/libhttplib2.html#cache-objects) illustrates a pretty minimal interface, requiring only ```get```, ```set``` and ```delete``` methods. All of these operations are provided on the built-in dictionary object (the ```dict``` type) in Python so extending or wrapping that object would hopefully give us a really simple cache object in very few lines of code.

I chose to extend the ```dict``` type and it's necessary to do that because although the type provides get, set and delete operations it doesn't expose them via quite that interface. The ```get``` method is available, returning ```None``` if the key doesn't exist, but to set a value against a key in a dictionary you need to use the square bracket syntax:

    my_dict = {}
    my_dict['key'] = 'Value'

Similarly, deletion is achieved via the ```del``` keyword:

    del my_dict['key']

Fortunately, both of these operations make calls to magic methods under the hood so providing the necessary api is as easy as:

    class Cache(dict):

        def set(self, key, value):
            self.__setitem__(key, value)

        def delete(self, key):
            self.__delitem__(key)

Super simple - and construction an object to make HTTP requests and cache them in-memory with ```httplib2``` just looks like:

    http_client = httplib2.Http(Cache())

Or so I thought...

Testing the api for the ```Cache``` object worked exactly as expected: keys got set, values got got and values got deleted. The problem was that the cacheable endpoints that I was testing against kept getting hit when the client should have been getting them from the cache that I'd lovingly crafted for it. What was going wrong?

I tracked the problem down to this line in the ```request``` method on the ```Http``` object in ```httplib2```:

    ...
    if self.cache:
    ...

Of course, the client will only attempt to fetch from or store in the cache if there is one there to use - very sensible. However, I'd extended the ```dict``` type and being that no requests had been made it was empty and an empty dictionary evaluates to ```False``` in those situations - running ```bool({})``` in the Python REPL illustrates that nicely.

Under the hood, finding the 'truthiness' of objects results in another magic method call, this time to ```__nonzero__```. To make sure the ```Http``` object recognised that there was a cache available to use the ```__nonzero__``` method on my object just needed to return ```True```:

    ...
    def __nonzero__(self):
        return True

With that in place the cache works as expected.
