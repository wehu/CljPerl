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

### TODO

