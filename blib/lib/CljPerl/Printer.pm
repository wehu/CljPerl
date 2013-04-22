package CljPerl::Printer;

  use strict;
  use warnings;

  sub to_string {
    my $obj = shift;
    my $class = $obj->class();
    my $s = "";
    if($class eq "Seq") {
      $s = "(";
      foreach my $i (@{$obj->value()}) {
        $s .= to_string($i) . " ";
      }
      $s .= ")";
    } else {
      $s = $obj->value();
    };
    return $s;
  }

1;

