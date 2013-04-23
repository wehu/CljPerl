package CljPerl::Printer;

  use strict;
  use warnings;

  sub to_string {
    my $obj = shift;
    my $class = $obj->class();
    my $type = $obj->type();
    my $s = "";
    if($class eq "Seq") {
      $s = "(";
      foreach my $i (@{$obj->value()}) {
        $s .= to_string($i) . " ";
      }
      $s .= ")";
    } else {
      if($type eq "vector") {
        $s = "[";
        foreach my $i (@{$obj->value()}) {
          $s .= to_string($i) . " ";
        }
        $s .= "]";
      } elsif($type eq "map" or $type eq "meta") {
        $s = "{";
        foreach my $i (keys %{$obj->value()}) {
          $s .= $i . "=>" . to_string($obj->value()->{$i}) . " ";
        }
        $s .= "}";
      } elsif($type eq "function" or $type eq "macro") {
        $s = to_string($obj->value());
      } else {
        $s = $obj->value();
      };
    };
    return $s;
  }

1;

