package CljPerl::Var;

  use strict;
  use warnings;

  our $VERSION = '0.10';

  sub new {
    my $class = shift;
    my $name = shift;
    my $value = shift;
    my $self = {class=>$class,
                name=>$name,
	        value=>$value};
    bless $self;
    return $self;
  }

  sub name {
    my $self = shift;
    return $self->{name};
  }

  sub value {
    my $self = shift;
    my $value = shift;
    if(defined $value){
      $self->{value} = $value;
    } else {
      return $self->{value};
    }
  }

1;
