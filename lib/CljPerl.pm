package CljPerl;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use File::Spec;

require Exporter;

use CljPerl::Evaler;

our @ISA = qw(Exporter);

# This allows declaration	use CljPerl ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

sub print {
  print @_;
}

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

sub use_lib {
  my $path = shift;
  unshift @INC, $path;
}

my $lib_path = File::Spec->rel2abs(dirname(__FILE__));
use_lib($lib_path);

sub gen_name {
  return "gen-" . rand;
}

1;
__END__

=head1 NAME

CljPerl - A lisp on perl.

=head1 SYNOPSIS

        (defmacro defn [name args & body]
          `(def ~name
             (fn ~args ~@body)))

        (defn foo [arg]
          (println arg))

        (foo "hello world!") ;comment here

=head1 DESCRIPTION

CljPerl is a lisp implemented by Perl. It borrows the idea from Clojure,
which makes a seamless connection with Java packages.
Like Java, Perl has huge number of CPAN packages.
They are amazing resources. We should make use of them as possible.
However, programming in lisp is more insteresting.
CljPerl is a bridge between lisp and perl. We can program in lisp and
make use of the great resource from CPAN.

=head2 EXPORT

=head3 Lisp <-> Perl

CljPerl is hosted on Perl. Any object of CljPerl can be passed into Perl and vice versa including code.

An example of using Perl's IO functions.

=head4 Perl functions in CljPerl.pm

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
	
=head4 CljPerl functions in core.clp

	(ns file
	  (defn open [file cb]
	    (. open file cb))
	
	  (defn >> [fh str]
	    (. puts fh str))
	
	  (defn << [fh]
	    (. readline fh)))

=head4 Test

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

=head3 Documents

=head4 Reader

 * Reader forms

   * Symbols :

	foo, foo#bar

   * Literals
 
   * Strings :

	"foo", "\"foo\tbar\n\""

   * Numbers :

	1, -2, 2.5

   * Booleans :

	true, false

   * Keywords :

	:foo

 * Lists :

	(foo bar)

 * Vectors :

	[foo bar]

 * Maps :

	{:key1 value1 :key2 value2 "key3" value3}


=head4 Macro charaters

 * Quote (') :

	'(foo bar)

 * Comment (;) :

	; comment

 *  Dispatch (#) :

   * Accessor (:) :

	#:0 ; index accessor
	#:"key" ; key accessor
	#::key  ; key accessor

 * Metadata (^) :

	^{:key value}

 * Syntax-quote (`) :

	`(foo bar)

 * Unquote (~) :

	`(foo ~bar)

 * Unquote-slicing (~@) :

	`(foo ~@bar)

=head4 Builtin Functions

 * list :

	(list 'a 'b 'c) ;=> '(a b c)

 * car :

	(car '(a b c))  ;=> 'a

 * cdr :

	(cdr '(a b c))  ;=> '(b c)

 * cons :

	(cons 'a '(b c)) ;=> '(a b c)

 * key accessor :

	(#::a {:a 'a :b 'a}) ;=> 'a

 * keys :

	(keys {:a 'a :b 'b}) ;=> (:a :b)

 * index accessor :

	(#:1 ['a 'b 'c]) ;=> 'b

 * length :

	(length '(a b c)) ;=> 3
	(length ['a 'b 'c]) ;=> 3
	(length "abc") ;=> 3

 * append :

	(append '(a b) '(c d)) ;=> '(a b c d)
	(append ['a 'b] ['c 'd]) ;=> ['a 'b 'c 'd]
	(append "ab" "cd") ;=> "abcd"

 * type :

	(type "abc") ;=> "string"
	(type :abc)  ;=> "keyword"
	(type {})    ;=> "map"

 * meta :

	(meta foo ^{:m 'b})
	(meta foo) ;=> {:m 'b}

 * fn :

	(fn [arg & args]
	  (println 'a))

 * apply :

	(apply list '(a b c)) ;=> '(a b c)

 * eval :

	(eval "(+ 1 2)")

 * require :

	(require "core")

 * def :

	(def foo "bar")
	(def ^{:k v} foo "bar")

 * set! :

	(set! foo "bar")

 * let :

	(let [a 1
	      b a]
	  (println b)) 

 * defmacro :

	(defmacro foo [arg & args]	
	  `(println ~arg)
	  `(list ~@args))

 * if :

	(if (> 1 0)
	  (println true)
	  (println false))
	  
	(if true
	  (println true))

 * while :

	(while true
	  (println true))

 * begin :

	(begin
	  (println 'foo)
	  (println 'bar))

 * perl->clj :

 * ! :

	(! true) ;=> false

 * + - * / % == != >= <= > < : only for number.

 * eq ne : only for string.

 * equal : for all objects.

 * . : (.[perl namespace] method args ...)

	(.CljPerl print "foo")

 * -> : (->[perl namespace] method args ...)
   Like '.', but this will pass perl namespace as first argument to perl method.

 * println

	(println {:a 'a})

 * trace-vars : Trace the variables in current frame.

	(trace-vars)

=head4 Core Functions

 * use-lib : append path into Perl and CljPerl files' searching paths.

	(use-lib "path")

 * ns : CljPerl namespace.

	(ns "foo"
	  (println "bar"))

 * defn :

	(defn foo [arg & args]
	  (println arg))

 * defmulti :

 * defmethod :

 * reduce :

 * map :

 * file#open : open a file with a callback.

	(file#open ">file"
	  (fn [fh]
	    (file#>> fn "foo")))

 * file#<< : read a line from a file handler.

	(file#<< fh)

 * file#>> : write a string into a file handler.

	(file#>> fh "foo")

=head1 SEE ALSO

=head1 AUTHOR

Wei Hu, E<lt>huwei04@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Wei Hu. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
