### CljPerl

CljPerl is a lisp implemented by Perl. It borrows the idea from Clojure,
which makes a seamless connection with Java packages.
Like Java, Perl has huge number of CPAN packages.
They are amazing resources. We should make use of them as possible.
However, programming in lisp is more insteresting.
CljPerl is a bridge between lisp and perl. We can program in lisp and
make use of the great resource from CPAN.

### Example

	;; file t.clp
	(defmacro defn [name args & body]
	  `(def ~name
	     (fn ~args ~@body)))
	
	(defn foo [arg]
	  (println arg))
	
	(foo "hello world!") ;comment here
	
	(foo :abc)
	
	(.CljPerl print "Hi\n")
	
	(. print "Guy\n")

	------------------

	> bin/cljp t.clp
