title: Resolving Javascript Promises using Events
date: 2012-06-17
url_code: resolving-javascript-promises-using-events

In playing around with Node.js I wrote a simple ‘view’ module for which I had a particular API in mind. I wanted to be able to pass it a file to instantiate it, set variables on the object and then render it. This was complicated slightly by the asynchronous file access getting the template file and I decided, correctly or not, to handle this using a promise and an event emitter.

For templating this module uses Underscore’s ‘template’ function. This will compile the string given to it (the contents of the file in this case) into a function which then returns the final string when it’s called. The function accepts an object of variables to replace. In my ‘view’ the render function calls this function, passing in any variables set on the view object.

The API I wanted to use was along the lines of:

    view = new View(‘./views/index.jhtml’);
    view.set(‘title’, ‘Hello World’);
    content = view.render();

With this in mind the constructor needed to return an instance of the object so that the other methods could be called on it. No problem. The complication comes when we want to call ‘render’. The template file is read asynchronously so the contents isn’t necessarily available at that time.

    function View(template) {

        var self = this;
        this.compiledTemplate;
        this.data = {};

        readFile(template, function(err, contents) {
            if(!err) {
                self.compiledTemplate = _.template(contents.toString());
            }
        });
        return this;
    }

    View.prototype.set = function(key, value) {
        this.data[key] = value;
        return this;
    }

    View.prototype.render = function() {
        // What happens when the file hasn't been read yet?
        return this.compiledTemplate(this.viewData);
    }

The way I solved this was to have the render function return either the string, if it is available, or return a promise (wiki.commonjs.org/wiki/Promises/A) for the string. The promise is then resolved internally by an event that’s emitted in the callback to the ‘readFile’ function.

    var Emitter = require('events').EventEmitter,
        eventName = 'template';
     
    function View(template) {

        var self = this;
        this.compiledTemplate;
        this.data = {};
        // Create an event emitter
        this.event = new Emitter();

        readFile(template, function(err, contents) {
            if(!err) {
                self.compiledTemplate = _.template(contents.toString());
                // When the file's ready, emit an event.
                self.event.emit(eventName);
            }
        });

        return this;
    }

    View.prototype.render = function() {
        var self = this;
        if(this.compiledTemplate) {
            // If we've got it then just pass it the data and return
            return this.compiledTemplate(this.data);
        }
        else {
            var promise = new Promise();
            self.event.on(eventName, function(){
                // When the event fires resolve the Promise with the template
                promise.resolve(self.compiledTemplate(self.data));
            });
            // Return the Promise
            return promise;
        }
    }

The resulting View function can be seen here: [https://github.com/grahamlyons/nada/blob/master/lib/view.js](https://github.com/grahamlyons/nada/blob/master/lib/view.js).
