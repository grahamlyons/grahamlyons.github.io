---
layout: post
title: Investigating Local Variable Scope in Python with the 'dis' Module
date: 2013-05-02
permalink: /article/investigating-local-variable-scope-in-python-with-the-dis-module
---

Compared to something like Javascript, scoping in Python is pretty easy to follow. However, I found a situation recently which was confusing at first glance until I examined the Python byte code using the ```dis``` module (_"dis - Disassembler of Python byte code into mnemonics"_, from the help documentation).

The situation was as follows: the set up of a test class was redefining a class to a mock value, but preserving the original class to be restored later. What happened was that an ```UnboundLocalError``` was thrown, but only when a line _below_ it (quite a long way below it, which was tricky to spot at first) was present. It looked something like this stripped-down example:

    class RealClass(object): pass

    class Dummy(object): pass

    class Test(object):

        def test(self):
            d = RealClass
            RealClass = Dummy
        

    if __name__ == "__main__":
        t = Test()
        t.test()
        
Putting that whole lot in a file and running it gives:

    $ python scope.py
    Traceback (most recent call last):
      File "scope.py", line 15, in <module>
        t.test()
      File "scope.py", line 9, in test
        d = RealClass
    UnboundLocalError: local variable 'RealClass' referenced before assignment

Ordinarily a _"local variable 'x' referenced before assignment"_ error would be fairly trivial but what was confusing was that the behaviour changed when the line ```RealClass = Dummy``` was removed - the line _after_ where the error was thrown. To see what was going on I used the ```dis``` function from the ```dis``` module to see what instructions were being run on the Python VM.

The first look was at the piece of code which didn't throw an error e.g.:

    ...
    def test(self):
        d = RealClass

    ...

Fire up a Python shell, import the required code (the example code above is in a file called ```scope.py``` in the local directory) and run the ```dis``` function on the ```test``` method on the ```Test``` object:

    >>> from scope import *
    >>> from dis import dis
    >>> dis(Test.test)
      9           0 LOAD_GLOBAL              0 (RealClass)
                  3 STORE_FAST               1 (d)
                  6 LOAD_CONST               0 (None)
                  9 RETURN_VALUE        
    >>> 

From this we can see that a global variable (```RealClass```) is being loaded and stored against the local variable ```d``` (then ```None``` is loaded and returned by the function, but that's an aside to this).

Restoring the line "```RealClass = Dummy```" and re-running this process shows the following output from ```dis```:

      9           0 LOAD_FAST                1 (RealClass)
                  3 STORE_FAST               2 (d)

     10           6 LOAD_GLOBAL              0 (Dummy)
                  9 STORE_FAST               1 (RealClass)
                 12 LOAD_CONST               0 (None)
                 15 RETURN_VALUE

So this shows that, rather than being loaded from the global scope (```LOAD_GLOBAL```), ```RealClass``` is being loaded locally (```LOAD_FAST```) and of course it can't be found. The line below it loads the ```Dummy``` variable from the global scope and stores it against a local variable, ```RealClass```; it's this which has affected the instruction above it.

Assigning to a variable anywhere within a particular scope means that the instruction to the Python VM anywhere else in the same scope is to load it from there. This can be confusing when the use of the variable and the assignment are quite far away from one another.
