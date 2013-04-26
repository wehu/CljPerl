# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CljPerl.t'

#########################

use Test::More tests=>2;
BEGIN { use_ok('CljPerl') };

my $test = CljPerl::Evaler->new();

$test->load("core");
$test->load("file");
ok($test->load("t/file.clp"), 'file operations');

