---
title: The Quickest Way to Run Python in Docker
published: true
description: What's the least effort required to get some Python into a Docker container?
tags: #python, #docker
cover_image: https://thepracticaldev.s3.amazonaws.com/i/643t1nq0fe4kmwpvnh7h.png
permalink: /article/the-quickest-way-to-run-python-in-docker
---

I love Python. I think it's a beautifully designed language with a philosophy that I really appreciate as a developer trying to get stuff done. Just run this at a command prompt: `python -m this`

```
Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
If the implementation is easy to explain, it may be a good idea.
Namespaces are one honking great idea -- let's do more of those!
```

What's not so nice is Python packaging. It's awkward, it's confusing - it's getting better but it's still not nearly as nice as it is in other languages (Ruby, Java, Javascript).

Docker is a collection of various Linux features  - namespaces, cgroups, union file-system - put together in such a way that you can package and distribute software in a language-agnostic container. Docker is a great way to skirt the pain of Python packaging.

To install it, go to https://www.docker.com/ and under the "Get Docker" link choose the version for your operating system.

## Just Enough Docker

So. What's the least we can get away with? Or, what's the least I can write to illustrate this? Well, if we use the `onbuild` Python Docker image, then not much.

Imagine we have a super-simple Flask app which just has one route, returning a fixed string (Hello, World?). We need very little, but we do have the dependency on Flask. Even on my Mac, with the latest OS (OK, not High Sierra just yet), the default Python installation doesn't include the `pip` package manager. What the hell? It does include `easy_install`, so I could `easy_install pip`, or rather `sudo easy_install pip` because it'll go in a global location. Then I could globally install the `flask` package too. Woop-de-doo. Which version is now globally installed on my system? Who knows!(?)

Let's not do that. Let's create our `requirements.txt` file:
```shell
echo Flask > requirements.txt
```

And our Flask app:
```python
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    return 'Hello, World!'


if __name__ == '__main__':
    app.run(host='0.0.0.0')
```

And _then_ let's have a `Dockerfile` too:
```shell
echo FROM python:onbuild >> Dockerfile
```

## Build It

OK, so let's build it:
```shell
$ docker build -t myapp.local .
Sending build context to Docker daemon  4.096kB
Step 1/1 : FROM python:onbuild
# Executing 3 build triggers...
Step 1/1 : COPY requirements.txt /usr/src/app/
 ---> Using cache
Step 1/1 : RUN pip install --no-cache-dir -r requirements.txt
 ---> Using cache
Step 1/1 : COPY . /usr/src/app
 ---> Using cache
 ---> 79fdf87107de
Successfully built 79fdf87107de
Successfully tagged myapp.local:latest
```

Was that it? Is it built? Yup:
```shell
$ docker image ls myapp.local
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
myapp.local         latest              c58ad169cb28        4 seconds ago       700MB
```

## Run It

Great, our app is inside a container! What next? Run the container like this:
```shell
$ docker run --rm myapp.local python server.py
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
```

That tells the `docker` command to `run` the `myapp.local` container (which we built), to remove it when it stops (`--rm`) and to run the command `python server.py` inside it. Amazing! So can we see our app now?

## The Final Piece

We can't see our app at the moment because although it's running perfectly inside the container it's not accessible anywhere else. The message we get when we run it says it's listening on port `5000`, but if we try to access that on the same host we get an error:
```shell
$ curl localhost:5000
curl: (7) Failed connect to localhost:5000; Connection refused
```

We need to expose the port outside the container that it's running in:
```shell
docker run --rm -p 5001:5000 myapp.local python server.py
```

The `-p` argument maps your local `5001` port to `5000` inside the container (they can just be the same but I've made them different just to illustrate where the host and container ones are).

## OK, not quite the end...

So I found out when I was writing this that:
> The ONBUILD image variants are deprecated, and their usage is discouraged.

That's OK - you wouldn't really use the `ONBUILD` image for anything serious, and the `Dockerfile` that defines it is very easy to understand. Check it out for yourself and see how it works: https://github.com/docker-library/python/blob/f12c2d/3.6/jessie/onbuild/Dockerfile

We can replace the contents of our `Dockerfile` with the following and get the same result:
```Dockerfile
FROM python

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /usr/src/app
```

I've just removed the `ONBUILD` directives (plus the `3.6-jessie` Python version - we can just take the latest).

## Really The End

So that's our minimal example of how to run a Python app with its dependencies inside a Docker container. Docker is an amazing piece of technology and it's no surprise that the [company](https://www.bloomberg.com/news/articles/2017-08-09/docker-is-said-to-be-raising-funding-at-1-3-billion-valuation) is [valued](https://www.sdxcentral.com/articles/news/sources-microsoft-tried-to-buy-docker-for-4b/2016/06/) so [highly](https://www.forbes.com/sites/mikekavis/2015/07/16/5-reasons-why-docker-is-a-billion-dollar-company/#47e077c1f04f). In this instance it provides a clean way for us to avoid pain with Python packaging, but we now also have a container image with our app inside which could be distributed and run on any other system which can run Docker.

