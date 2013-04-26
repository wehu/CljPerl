## Reader

#### Reader forms

##### Symbols :

	foo, foo#bar

##### Literals
 
###### Strings :

	"foo", "\"foo\tbar\n\""

###### Numbers :

	1, -2, 2.5

###### Booleans :

	true, false

###### Keywords :

	:foo

##### Lists :

	(foo bar)

##### Vectors :

	[foo bar]

##### Maps :

	{:key1 value1 :key2 value2 "key3" value3}


#### Macro charaters

##### Quote (') :

	'(foo bar)

##### Comment (;) :

	; comment

##### Metadata (^) :

	^{:key value}

##### Syntax-quote (`) :

	`(foo bar)

##### Unquote (~) :

	`(foo ~bar)

##### Unquote-slicing (~@) :

	`(foo ~@bar)

## Builtin Functions

##### list :

	(list 'a 'b 'c) ;=> '(a b c)

##### car :

	(car '(a b c))  ;=> 'a

##### cdr :

	(cdr '(a b c))  ;=> '(b c)

##### cons :

	(cons 'a '(b c)) ;=> '(a b c)

##### key accessor :

	(:a {:a 'a :b 'a}) ;=> 'a

##### keys :

	(keys {:a 'a :b 'b}) ;=> (:a :b)

##### index accessor :

	(1 ['a 'b 'c]) ;=> 'b

##### length :

	(length '(a b c)) ;=> 3
	(length ['a 'b 'c]) ;=> 3
	(length "abc") ;=> 3

##### append :

	(append '(a b) '(c d)) ;=> '(a b c d)
	(append ['a 'b] ['c 'd]) ;=> ['a 'b 'c 'd]
	(append "ab" "cd") ;=> "abcd"

##### type :

	(type "abc") ;=> "string"
	(type :abc)  ;=> "keyword"
	(type {})    ;=> "map"

##### meta :

	(meta foo ^{:m 'b})
	(meta foo) ;=> {:m 'b}

##### fn :

	(fn [arg & args]
	  (println 'a))

##### apply :

	(apply list '(a b c)) ;=> '(a b c)

##### eval :

	(eval "(+ 1 2)")

##### require :

	(require "core")

##### def :

	(def foo "bar")
	(def ^{:k v} foo "bar")

##### set! :

	(set! foo "bar") 

##### defmacro :

	(defmacro foo [arg & args]	
	  `(println ~arg)
	  `(list ~@args))

##### if :

	(if (> 1 0)
	  (println true)
	  (println false))
	  
	(if true
	  (println true))

##### while :

	(while true
	  (println true))

##### begin :

	(begin
	  (println 'foo)
	  (println 'bar))

##### perl->clj :

##### ! :

	(! true) ;=> false

##### + - * / % == != >= <= > < : only for number.

##### eq ne : only for string.

##### equal : for all objects.

##### . : (.[perl namespace] method args ...)

	(.CljPerl print "foo")

##### -> : (->[perl namespace] method args ...)
   Like '.', but this will pass perl namespace as first argument to perl method.

##### println

	(println {:a 'a})

##### trace-vars : Trace the variables in current frame.

	(trace-vars)

## Core Functions

##### use-lib : append path into Perl and CljPerl files' searching paths.

	(use-lib "path")

##### ns : CljPerl namespace.

	(ns "foo"
	  (println "bar"))

##### defn :

	(defn foo [arg & args]
	  (println arg))

##### defmulti :

##### defmethod :

##### reduce :

##### map :

##### file#open : open a file with a callback.

	(file#open ">file"
	  (fn [fh]
	    (file#>> fn "foo")))

##### file#<< : read a line from a file handler.

	(file#<< fh)

##### >> : write a string into a file handler.

	(file#>> fh "foo")

## Misc

## TODO
