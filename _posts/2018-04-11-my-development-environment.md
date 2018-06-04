---
title: Why My Development Environment is the Best
published: true
description: How I set up my computer for local development
tags: devtips,productivity,infrastructure,development
cover_image: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/MacBook_Running_Virtual_Machine.svg/800px-MacBook_Running_Virtual_Machine.svg.png
permalink: /article/why-my-development-environment-is-the-best
---

_Or more accurately, what works for me right now._

As software developers we spend a lot of our day at the keyboard, typing. It's natural that we spend time making that environment a pleasant and productive place in which to work.

Local development environments are often very personal and are tweaked and customised to the tastes of the individual developer. There are a finite number of editors and IDEs but an almost infinite combination of plugins, themes and customisations within those. In some of the more recent evolutions of my local environment I've rebelled against the culture of personalisation.

## My Tools

Almost all the software I write gets deployed and run in production on a server running some flavour of Linux. I run everything locally on a [virtual machine](https://en.wikipedia.org/wiki/Virtual_machine) which is set up as close to production as I can get. Over the years this has been invaluable for catching bugs before they even get to a staging environment or reproducing production problems under safe conditions.

To manage and run virtual machines (VMs) I use the combination of [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/). Once I've installed those I'm (nearly) ready to run a VM. I also use the [vagrant-vbguest plugin](https://github.com/dotless-de/vagrant-vbguest) which manages the installation of the VirtualBox Guest Additions in the VM itself. These are used to share a workspace directory between my host machine and the Linux VM: `vagrant plugin install vagrant-vbguest`

The configuration for a VM managed by Vagrant can be stored as code so here's an example on GitHub of the main environment I use at the moment: https://github.com/grahamlyons/centos-dev

To run it: clone the repo, start the VM and then connect to it:
```shell
git clone git@github.com:grahamlyons/centos-dev.git
cd centos-dev
vagrant up && vagrant ssh -c 'tmux attach || tmux'
```

The instructions in the `Vagrantfile` start from a CentOS 7 base image and:
 - specify a fixed IP address which can be used to refer to the VM
 - mount a local `~/workspace/` directory inside the VM (at the same path)
 - install some base packages, e.g. `tmux`, `vim`, `git` etc.
 - install and sets up Docker
 - copy some local configuration and credential files into the VM

The SSH connection command also puts me into either an existing [tmux](https://en.wikipedia.org/wiki/Tmux) session or starts a new one. Tmux is a great tool for creating multiple tabs and panes in a single SSH session. I don't use any extra configuration for it beyond what's installed on CentOS with the package.

### Benefits of a Virtual machine

The first time I was introduced to working inside a VM I was sold on it completely. It made so much sense to me to be as close to production as possible and installing software on Linux, using a proper package manager, is so much nicer than on OSX (or Windows - in the depths of my memory).

With the shared folder - `~/workspace/` in my case - I can use whatever editor I like on my host OS and the changes will always be inside the VM, ready to run.

Running a VM has also saved me from completely destroying my machine on more than one occasion, the worst of which was an accidental `rm -rf /` run as `root`. Always having a working machine that you can use to search for help with fixing problems is incredibly useful. If things get really back you can just destroy it and start again from your known good state.

### Drawbacks of a Virtual machine

Using a VM is not a perfect solution and running code inside a directory shared between the host machine and the guest VM can give performance problems. The shared directory is great for use with a simple editor but with an IDE, which will want to run your code for you, it can be complicated or impossible to run the code inside the virtual machine.

## My Editor

The first editor I ever used when I started working professionally was [Homesite](https://en.wikipedia.org/wiki/Macromedia_HomeSite), which betrays my vintage. After I was no longer able to get hold of that I looked around for something else and saw something called [Vim](https://www.vim.org/) recommended. I was interested and downloaded it and opened it up. After a few minutes I managed to work out how to quit it and didn't open it up again for a year or two.

### Vim

After throwing myself into Vim I now use it almost exclusively. Where I use something else I try to find a Vim key-bindings plugin for it. There is a big learning curve for Vim, and `vimtutor` was a big help, but now that I'm familiar with the movements and actions nothing lets me manipulate text faster.

### Plugins and Configuration

My `.vimrc` file has gone through many iterations and it's now roughly 10 lines:
```vim
set expandtab
set shiftwidth=4
set tabstop=4

set modeline
set modelines=5

set nu
set colorcolumn=80

syntax enable

let g:netrw_liststyle=3
if exists("*netrw_gitignore#Hide")
    let g:netrw_list_hide=netrw_gitignore#Hide()
endif
```

I use spaces instead of tabs (who wouldn't?); (for OSX, where it was turned off) it's set to read Vim settings from the tops of files (http://vim.wikia.com/wiki/Modeline_magic); line numbers and syntax highlighting are on; there's a column at 80 characters to stop my lines from getting too long and I've set directory listings to look like a tree.

Everything else I use in Vim is vanilla. Just getting used to the defaults allows me to move between different machines more easily and there's less of my clever customisation and tweaking to remember and more widely available documentation to refer to.

## Other Software

Over the past couple of years I've started running almost everything inside Docker containers so I'm `yum install`ing less and less. Almost everything is available in an image from Docker Hub and it's so fast to start up once it's been pulled down that it just makes so much sense. Running different versions of e.g. Node, Ruby or Python side by side is much simpler.

I still use `yum` to install utility packages like `telnet` or `jq`, and they'll often make it into the configuration in the `Vagrantfile`.

## This Works for Me for Now

So this is how my machine is set up at the moment, and it works really well for me. I run OSX and spend most of the time in Terminal, with one tab for my VM connection. I use Vim both on OSX and on the VM, and the same for Git.

It works well but I am always making changes. The introduction of Docker is more recent and is becoming more prominent. Let's see what this looks like in a year.
