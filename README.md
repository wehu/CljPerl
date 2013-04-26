# CljPerl

CljPerl is a Lisp implemented by Perl. It borrows the idea from Clojure,
which makes a seamless connection with Java packages.
Like Java, Perl has huge number of CPAN packages.
They are amazing resources. We should make use of them as possible.
However, programming in Lisp is more insteresting.
CljPerl is a bridge between Lisp and Perl. We can program in Lisp and
make use of the great resources from CPAN.

## Example

	;; file t.clp
	(defmacro defn [name args & body]
	  `(def ~name
	     (fn ~args ~@body)))
	
	(defn foo [arg]
	  (println arg))
	
	(foo "hello world!") ;comment here
	
	(foo (+ 1 2))
	
	(.CljPerl print "Hi\n")
	
	(. print "Guy\n")

	(defmulti mf type)
	(defmethod mf "string" [a] (println "string"))
	(defmethod mf "keyword" [a] (println "keyword"))
	(mf "test")
	(mf :test)

	------------------

	> bin/cljp t.clp

## Lisp <-> Perl

CljPerl is hosted on Perl. Any object of CljPerl can be passed into Perl and vice versa including code.

An example of using Perl's IO functions.

####### Perl functions in CljPerl.pm

	package CljPerl;
	
	sub open {
	  my $file = shift;
	  my $cb = shift;
	  my $fh;
	  open $fh, $file;
	  &{$cb}($fh);
	  close $fh;
	}
	
	sub puts {
	  my $fh = shift;
	  my $str = shift;
	  print $fh $str;
	}
	
	sub readline {
	  my $fh = shift;
	  return <$fh>;
	}
	
####### CljPerl functions in core.clp

	(ns file
	  (defn open [file cb]
	    (. open file cb))
	
	  (defn >> [fh str]
	    (. puts fh str))
	
	  (defn << [fh]
	    (. readline fh)))

####### Test

	(file#open ">t.txt" (fn [f]
	  (file#>> f "aaa")))
	
	(file#open "<t.txt" (fn [f]
	  (println (perl->clj (file#<< f)))))

An advanced example which creates a timer with AnyEvent.

	(. require AnyEvent)

	(def cv (->AnyEvent condvar))
	
	(def count 0)
	
	(def t (->AnyEvent timer
	  {:after 1
	   :interval 1
	   :cb (fn [ & args]
	         (println count)
	         (set! count (+ count 1))
	         (if (>= count 10)
	           (set! t nil)))}))
	
	(.AnyEvent::CondVar::Base recv cv)

## Documents

See APIs.md
