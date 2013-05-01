package CljPerl::Logger;

  use strict;
  use warnings;

  our $VERSION = '0.05';

  sub error {
    my $msg = shift;
    die "[E] $msg";
  }

  sub info {
    my $msg = shift;
    print "[I] $msg";
  }

  sub warn {
    my $msg = shift;
    print "[W] $msg";
  }

  sub debug {
    my $msg = shift;
    print "[D] $msg";
  }

1;

