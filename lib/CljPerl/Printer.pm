package CljPerl::Printer;

  use strict;
  use warnings;

  our $VERSION = '0.03';

  sub to_string {
    my $obj = shift;
    my $class = $obj->class();
    my $type = $obj->type();
    my $s = "";
    if($class eq "Seq") {
      if($type eq "vector") {
        $s = "[";
      } elsif(($type eq "map")) {
        $s = "{";
      } else {
        $s = "(";
      }
      foreach my $i (@{$obj->value()}) {
        $s .= to_string($i) . " ";
      }
      if($type eq "vector") {
        $s .= "]";
      } elsif(($type eq "map")) {
        $s .= "}";
      } else {
        $s .= ")";
      }
      $s =~ s/ ([\)\]\}])$/$1/;
    } else {
      if($type eq "vector") {
        $s = "[";
        foreach my $i (@{$obj->value()}) {
          $s .= to_string($i) . " ";
        }
        $s .= "]";
        $s =~ s/ \]$/\]/;
      } elsif($type eq "map" or $type eq "meta") {
        $s = "{";
        foreach my $i (keys %{$obj->value()}) {
          $s .= $i . "=>" . to_string($obj->value()->{$i}) . " ";
        }
        $s .= "}";
        $s =~ s/ \}$/\}/;
      } elsif($type eq "function" or $type eq "macro") {
        $s = to_string($obj->value());
      } else {
        $s = $obj->value();
      };
    };
    return $s;
  }

1;

