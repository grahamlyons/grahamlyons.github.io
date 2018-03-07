title: Debugging circular module imports in Python with pdb
date: 2013-03-23
url_code: debugging-circular-module-imports-in-python-with-pdb

I find myself in awe of anyone who can competently use [gdb](http://www.gnu.org/software/gdb/). Occasionally I find myself dipping into it and pulling out some very basic information but that's about my limit. When I saw that Python had a similarly named [pdb](http://docs.python.org/2/library/pdb.html) module I was instantly intrigued because I write a lot more Python than I do C. 

Circular module imports in Python are a pretty trivial bug and if you run into them it will strongly suggest that the code should be in the same module. Nonetheless, I did recently run into one and it took me a bit longer than it should have to realise what was going on... As part of the investigation, I ran pdb on the code which was very enlightening and so I decided to write up what I did and what I found. 

So you've got module ```a``` containing class ```A``` and module ```b``` that has class ```B``` and for some reason module ```a``` uses class ```B``` and module ```b``` uses class ```A``` - all very convoluted.

    # Module a.py
    import os
    import sys # Another couple of imports to make things more interesting.
    from b import B

    class A: pass


    # Module b.py
    import json # Again, this just gives us more to look at.
    from a import A

    class B: pass


Now running either of these files in the Python interpreter will raise an ```ImportError```. The error will occur in the module being run when it tries to import the second.

    python -m pdb a.py


Running the command above puts us into the pdb shell at the top of the ```a``` module.

    > /tmp/py/a.py(1)<module>()
    -> import os
    (Pdb) 


In this shell the command ```s``` (or ```step```) steps over the lines of code being executed (hitting 'Enter' repeats the last command).

    (Pdb) s
    > /tmp/py/a.py(2)<module>()
    -> import sys
    (Pdb) 
    > /tmp/py/a.py(3)<module>()
    -> from b import B
    (Pdb) 
    --Call--
    > /tmp/py/b.py(1)<module>()
    -> import json
    (Pdb) 
    > /tmp/py/b.py(1)<module>()
    -> import json


So the ```sys``` module is imported then the class ```B``` from module ```b``` (not at all contrived). At this point the debugger jumps over to the top of ```b.py``` where the ```json``` module is imported. Repeatedly calling ```step``` here will step through each line in the ```json``` module.

    (Pdb) 
    --Call--
    > /usr/lib64/python2.6/json/__init__.py(98)<module>()
    -> """
    (Pdb) 
    > /usr/lib64/python2.6/json/__init__.py(98)<module>()
    -> """
    (Pdb) 
    > /usr/lib64/python2.6/json/__init__.py(100)<module>()
    -> __version__ = '1.9'


Stepping through every line in that module could be very tedious so we can use the ```up``` command to go back up to the previous stack frame and calling ```n``` (```next```) to go onto the next frame before we continue to step:

    (Pdb) up
    > /tmp/py/b.py(1)<module>()
    -> import json
    (Pdb) n
    > /tmp/py/b.py(2)<module>()
    -> from a import A
    (Pdb) s


Of course after importing ```json``` we have asked to import from the ```a``` module so we go back to the top of there.

    --Call--
    > /tmp/py/a.py(1)<module>()
    -> import os
    (Pdb) 
    > /tmp/py/a.py(1)<module>()
    -> import os
    (Pdb) 
    > /tmp/py/a.py(2)<module>()
    -> import sys
    (Pdb) 
    > /tmp/py/a.py(3)<module>()
    -> from b import B


The first time through this code we were stepping through each line but we didn't go into the ```os``` or ```sys``` modules, presumably because something else had already imported and evaluated them.

This time the same is true of ```b```. When we get to that point we have already started to import that module so we don't go evaluate it, but equally the class ```B``` wasn't found (because we jumped back into ```a```) so the interpreter throws an ```ImportError``` when we step onto the next line.

    (Pdb) 
    ImportError: 'cannot import name B'


Continuing to step through will return up the call stack, back through ```b``` until we get the traceback.

Clearly classes which are this tightly coupled should be in the same module and the example is very contrived but I enjoyed how much pdb showed me what was going on. 
