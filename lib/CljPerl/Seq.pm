package CljPerl::Seq;

  use strict;
  use warnings;

  use CljPerl::Logger;
  use CljPerl::Printer;

  our $VERSION = '0.07';

  sub new {
    my $class = shift;
    my $type  = shift;
    $type = "list" if !defined $type;
    my $value = shift;
    my @seq = ();
    $value = \@seq if !defined $value;
    my $self = {class=>"Seq",
	        type=>$type,
                value=>$value,
                meta=>undef,
                pos=>{filename=>"unknown",
		      line=>0,
	              col=>0}};
    bless $self;
    return $self;
  }

  sub class {
    my $self = shift;
    return $self->{class};
  }

  sub type {
    my $self = shift;
    my $type = shift;
    if(defined $type) {
      $self->{type} = $type;
    } else {
      return $self->{type};
    }
  }

  sub meta {
    my $self = shift;
    my $meta = shift;
    if(defined $meta) {
      $self->{meta} = $meta;
    } else {
      return $self->{meta};
    }
  }

  sub value {
    my $self = shift;
    my $value = shift;
    if(defined $value) {
      $self->{value} = $value;
    } else {
      return $self->{value};
    }
  }

  sub prepend {
    my $self = shift;
    my $v = shift;
    unshift @{$self->{value}}, $v;
  }

  sub append {
    my $self = shift;
    my $v = shift;
    push @{$self->{value}}, $v;
  }

  sub size {
    my $self = shift;
    return scalar @{$self->{value}};
  }

  sub first {
    my $self = shift;
    return undef if($self->size() < 1);
    return $self->{value}->[0];
  }

  sub second {
    my $self = shift;
    return undef if($self->size() < 2);
    return $self->{value}->[1];
  }

  sub third {
    my $self = shift;
    return undef if($self->size() < 3);
    return $self->{value}->[2];
  }

  sub fourth {
    my $self = shift;
    return undef if($self->size() < 4);
    return $self->{value}->[3];
  }

  sub slice {
    my $self = shift;
    my @range = @_;
    return @{$self->{value}}[@range];
  }

  sub each {
    my $self = shift;
    my $blk = shift;
    foreach my $i (@{$self->{value}}) {
      $blk->($i) if defined $i;
    }
  }

  sub show {
    my $self = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;
    print $indent . "type: " . $self->{type} . "\n";
    print $indent . "(\n";
    $self->each(sub {$_[0]->show($indent . "  "); print $indent . "  ,\n";});
    print $indent . ")\n";
  }

  sub error {
    my $self = shift;
    my $msg = shift;
    $msg .= " [";
    $msg .= CljPerl::Printer::to_string($self);
    $msg .= "] @[file: " . $self->{pos}->{filename};
    $msg .= " ;line: " . $self->{pos}->{line};
    $msg .= " ;col: " . $self->{pos}->{col} . "]";
    CljPerl::Logger::error($msg);
  }

1;
