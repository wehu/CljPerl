# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CljPerl.t'

#########################

use Test::More tests=>3;
BEGIN { use_ok('CljPerl') };

my $test = CljPerl::Evaler->new();

ok($test->load("t/basic_syntax.clp"), 'basic syntax');

ok($test->eval("(def abc \"abc\")"), 'eval');

