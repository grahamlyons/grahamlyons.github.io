---
title: Machine Learning for the Lazy Beginner
published: true
description: An overview of classification using Javascript
tags: machinelearning,javascript
cover_image: https://thepracticaldev.s3.amazonaws.com/i/m1t3xxls09t25yk9c1a0.png
permalink: /article/machine-learning-for-the-lazy-beginner
---

# Machine Learning for the Lazy Beginner

This article was prompted by a tweet I saw which asked for a walkthrough on training a machine learning service to recognise new members of 3 different data sets.

> @rem: Being lazy here: I'm after a (machine learning) service that I can feed three separate datasets (to train with), and then I want to ask: "which dataset is _this_ new bit of content most like".
>
> Is there a walkthrough/cheatsheet/service for this?

My first thought was that this sounds like a [_classification_](https://en.wikipedia.org/wiki/Statistical_classification) task, and the idea that there are 3 sets of data should be the other way round: there is one set of data and each item in the set has one of 3 labels.

I didn't have a walkthrough in mind but I do know how to train a classifier to perform this exact task, so here is my walkthrough of classifying text documents using Javascript.

## Do You Have Adequate Supervision?

Machine learning can be classified (no pun intended) as either supervised or unsupervised. The latter refers to problems where the data you feed to the algorithm has no predetermined label. You might have a bunch of text documents and you want to find out if they can be grouped together into similar categories - that would be an example of [_clustering_](https://en.wikipedia.org/wiki/Cluster_analysis).

Supervised learning is where you know the outcome already. You have set of data in which each member fits into one of _n_ categories, for example a set of data on customers to your e-commerce platform, labelled according to what category of product they're likely to be interested in. You train your model against that data and use it predict what new customers might be interested in buying - this is an example of classification.

## Get in Training

For the classification task we've said that we "train" a model against the data we know the labels for. What that means is that we feed each instance in a dataset into the classifier, saying which label it should have. We can then pass the classifier a new instance, to which we don't know the label, and it will predict which class that fits into, based on what it's seen before.

There's a Javascript package called [`natural`](https://www.npmjs.com/package/natural) which has several different classifiers for working with text documents (natural language). Using one looks like this:

```javascript
const { BayesClassifier } = require('natural');
const classifier = new BayesClassifier();

// Feed documents in, labelled either 'nice' or 'nasty'
classifier.addDocument('You are lovely', 'nice');
classifier.addDocument('I really like you', 'nice');
classifier.addDocument('You are horrible', 'nasty');
classifier.addDocument('I do not like you', 'nasty');

// Train the model
classifier.train();

// Predict which label these documents should have
classifier.classify('You smell horrible');
// nasty
classifier.classify('I like your face');
// 'nice'
classifier.classify('You are nice');
// 'nice'
```

We add labelled data, train the model and then we can use it to predict the class of text we haven't seen before. Hooray!

## Performance Analysis

Training a machine learning model with a dataset of 4 instances clearly isn't something that's going to be very useful - its experience of the problem domain is very limited. Machine learning and big data are somewhat synonymous because the more data you have the better you can train your model, in the same way that the more experience someone has of a topic the more they're likely to know about it. So how do we know how clever our model is?

The way we evaluate supervised learning models is to split our data into a training set and a testing set, train it using one and test it using the other (I'll leave you to guess which way round). The more data in the training set the better.

When we get the predictions for our test data we can determine if the model accurately predicted the class each item is labelled with. Adding up the successes and errors will give us numbers indicating how good the classifier is. For example, successes over total instances processed is our accuracy; errors divided by the total is the error rate. We can get more in-depth analysis by plotting a [_confusion matrix_](https://en.wikipedia.org/wiki/Confusion_matrix) showing actual classes against predictions:

|             |       | Actual |       |
|    -----    | ----- |  ----- | ----- |
|             |       | _nice_ |_nasty_|
|**Predicted**|_nice_ |    21  | 2     |
|             |_nasty_|    1   | 10    |

This is really valuable for assessing performance when it's OK to incorrectly predict one class but not another. For example, when screening for terminal diseases it would be much better to bias for false positives and have a doctor check images manually rather than incorrectly give some patients the all clear.

## Train On All the Data

One way to train with as much data as possible is to use [_cross validation_](https://en.wikipedia.org/wiki/Cross-validation_%28statistics%29), where we take a small subset of our data to test on and use the rest for training. A commonly used technique is _k-fold_ cross validation, where the dataset is divided into _k_ different subsets (_k_ can be any number, even the number of instances in the dataset), each of which is used as a testing set while the rest is used for training - the process is repeated until each subset has been used for testing i.e. _k_ times.

![k-fold cross validation](https://upload.wikimedia.org/wikipedia/commons/1/1c/K-fold_cross_validation_EN.jpg)

## Tweet Data Example

I've put together an example using the `natural` Javascript package. It gets data from Twitter, searching for 3 different hashtags, then trains a model using those 3 hashtags as classes and evaluates the performance of the trained model. The output looks like this:

```
$ node gather.js
Found 93 for #javascript
Found 100 for #clojure
Found 68 for #python

$ node train.js
{ positives: 251, negatives: 10 }
Accuracy: 96.17%
Error: 3.83%
```

The code is on Github: [classification-js](https://github.com/grahamlyons/classification-js)

## Machine Learning is That Easy?!

Well, no. The example is really trivial and doesn't do any pre-processing on the gathered data: it doesn't strip out the hashtag that it searched for from the text (meaning that it would probably struggle to predict a tweet about Python that didn't include "#python"); it doesn't remove any [_stop words_](https://en.wikipedia.org/wiki/Stop_words) (words that don't really add any value, such as _a_ or _the_. In fact, `natural` does this for us when we feed documents in, but we didn't know that...); it doesn't expand any of the shortened URLs in the text (_learnjavascript.com_ surely means more than _t.co_). We don't even look at the gathered data before using it, for example graphing word-frequencies to get an idea of what we've got: are some of the "#python" tweets from snake enthusiasts talking about their terrariums?

To miss-quote Tom Lehrer, machine learning is like a sewer: what you get out depends on what you put in.

## Wrapping Up

The aim of this article was to give an overview of how a machine learning model is trained to perform a classification task. Hopefully, for the beginner, this goes some way to lifting the lid on some of that mystery.

_Cover image by: https://www.flickr.com/photos/mattbuck007/_
