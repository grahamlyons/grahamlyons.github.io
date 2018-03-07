title: How to call a function on each value in a Python dictionary
date: 2013-05-21
url_code: how-to-call-a-function-on-each-value-in-a-python-dictionary

Python has great support for mapping over lists or tuples, creating new structures containing the results of calling a function on the members of the original. I was looking for something similar for the values in a dictionary, maintaining the original keys, and I didn't find it described anywhere.

I'd written a little webapp using [Flask](http://flask.pocoo.org) and one of the routes took a number of float values in the URL. To make sure that these were indeed the floats I was looking for it seemed prudent to pass them into the ```float``` type and catch any ```ValueError``` that was raised (Flask does have a handler for floats in the routing it inherits from [Werkzeug](http://werkzeug.pocoo.org/), ```werkzeug.routing.FloatConverter```, but _"This converter does not support negative values"_). For the first pass at this I listed all the parameters to the function and then checked each one explicitly like this:

    @app.route("/route-with-floats/<first>/<second>/<third>/<fourth>")
    def route_with_floats(first, second, third, fourth):
        try:
            first = float(first)
            second = float(second)
            third = float(third)
            fourth = float(fourth)
        except ValueError:
            abort(404)

That worked fine but I wanted to find a way to condense it down a bit and it occurred that maybe I could use the ```**kwargs``` dictionary; I'd just need to map over that and pass each value into ```float```. For a ```list``` (or ```set``` or ```tuple``` etc.) the ```map``` function or list comprehensions would be a perfect fit and second nature to Python developers, but I couldn't recall ever doing anything similar for a ```dict```.

The solution I came up with passes a [generator expression](http://docs.python.org/2.7/glossary.html#term-generator-expression) which iterates over the items in a dictionary (each item is a ```tuple``` of the key and the value) into the ```dict``` callable. For an arbitrary function, ```func```, and a dictionary, ```d```, the solution looks like this:

    dict((v[0], func(v[1])) for v in d.items())

Plugging that into the Flask example above it now looks like this:

    @app.route("/route-with-floats/<first>/<second>/<third>/<fourth>")
    def route_with_floats(**kwargs):
        try:
            params = dict(
                (v[0], float(v[1])) for v in kwargs.items()
            )
        except ValueError:
            abort(404)

Arguably this is less readable and less explicit than the original form but I like the fact that it'll be the same regardless of the number of parameters i.e. values in the dictionary.

This should actually be described as a **dictionary comprehension**, a feature which is built into Python 3, and in fact the exact technique shown above is described in [PEP 274](http://www.python.org/dev/peps/pep-0274/). It's good to know that someone cleverer than me has already had the same idea.
