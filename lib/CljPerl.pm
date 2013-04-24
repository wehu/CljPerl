package CljPerl;

use 5.008008;
use strict;
use warnings;

require Exporter;

use CljPerl::Evaler;

our @ISA = qw(Exporter);

# This allows declaration	use CljPerl ':all';
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


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

1;
__END__

=head1 NAME

CljPerl - A lisp on perl.

=head1 SYNOPSIS

=head1 DESCRIPTION

CljPerl is a lisp implemented by Perl. It borrows the idea from Clojure,
which makes a seamless connection with Java packages.
Like Java, Perl has huge number of CPAN packages.
They are amazing resources. We should make use of them as possible.
However, programming in lisp is more insteresting.
CljPerl is a bridge between lisp and perl. We can program in lisp and
make use of the great resource from CPAN.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Wei Hu, E<lt>wehu@amd.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 The CljPerl Authors. All Rights Reserved.

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
