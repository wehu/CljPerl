package CljPerl::Printer;

  use strict;
  use warnings;

  our $VERSION = '0.09';

  sub to_string {
    my $obj = shift;
    return "" if !defined $obj;
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
      } elsif($type eq "xml") {
        $s = "<";
        $s .= $obj->{name};
        if(defined $obj->{meta}) {
          my %meta = %{$obj->meta()->value()};
          foreach my $i (keys %meta) {
            $s .= " " . $i . "=\"" . to_string($meta{$i}) . "\"";
          };
        };
        $s .= ">";
        foreach my $i (@{$obj->value()}) {
          $s .= to_string($i) . " ";
        };
        $s .= "</" . $obj->{name} . ">";
      } elsif($type eq "function" or $type eq "macro") {
        $s = to_string($obj->value());
      } else {
        $s = $obj->value();
      };
    };
    return $s;
  }

1;

