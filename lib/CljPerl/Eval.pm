package CljPerl::Eval;

#  use strict;
  use warnings;
  use CljPerl::Reader;
  use CljPerl::Var;
  use CljPerl::Printer;
  use File::Spec;

  sub new {
    my $class = shift;
    my @scopes = ({});
    my $self = {class=>$class,
                scopes=>\@scopes,
                syntaxquotation_scope=>0};
    bless $self;
    return $self;
  }

  sub scopes {
    my $self = shift;
    return $self->{scopes};
  }

  sub push_scope {
    my $self = shift;
    my $context = shift;
    unshift @{$self->scopes()}, \%{$context};
  }

  sub pop_scope {
    my $self = shift;
    shift @{$self->scopes()};
  }

  sub current_scope {
    my $self = shift;
    my $scope = @{$self->scopes()}[0];
    return $scope;
  }

  sub new_var {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $scope = $self->current_scope();
    $scope->{$name} = CljPerl::Var->new($name, $value);
  }

  sub var {
    my $self = shift;
    my $name = shift;
    my $scope = $self->current_scope();
    if(exists $scope->{$name}){
      return $scope->{$name};
    }
    return undef;
  }

  our $loaded_files = {};

  sub load {
    my $self = shift;
    my $file = shift;
    $file = File::Spec->rel2abs($file);
    return 1 if exists $loaded_files->{$file};
    $loaded_files->{$file} = 1;
    my $reader = CljPerl::Reader->new();
    $reader->read_file($file);
    $reader->ast()->each(sub {$self->_eval($_[0])});
    return 1;
  }

  sub eval {
    my $self = shift;
    my $str = shift;
    my $reader = CljPerl::Reader->new();
    $reader->read_string($str);
    $reader->ast()->each(sub {$self->_eval($_[0])});
    return 1;
  }

  our $keywords = {def=>1,
                  fn=>1,
		  defmacro=>1,
                  "."=>1,
                  "require"=>1,
	          println=>1};

  sub bind {
    my $self = shift;
    my $ast = shift;
    if($ast->type() eq "symbol" or
       ($ast->type() eq "dequotation" and $self->{syntaxquotation_scope} > 0)) {
      $ast->error("dequotation should be in syntax quotation scope")
        if ($ast->type() eq "dequotation" and $self->{syntaxquotation_scope} == 0);
      my $name = $ast->value();
      if($ast->type() eq "dequotation" and $ast->value() =~ /^@(\S+)$/) {
        $name = $1;
      }
      return $ast if exists $keywords->{$name} or $name =~ /^\.\S+$/;
      my $var = $self->var($name);
      $ast->error("unbound symbol") if !defined $var;
      return $var->value();
    } elsif($ast->type() eq "syntaxquotation" or $ast->type() eq "list") {
      $self->{syntaxquotation_scope} += 1 if $ast->type() eq "syntaxquotation";
      my $list = CljPerl::Seq->new("list");
      foreach my $i (@{$ast->value()}) {
        if($i->type() eq "dequotation" and $i->value() =~ /^@/){
          my $dl = $self->bind($i);
          $i->error("~@ should be given a list") if $dl->type() ne "list";
          foreach my $di (@{$dl->value()}){
            $list->append($di);
          };
        } else {
          $list->append($self->bind($i));
        }
      }
      $self->{syntaxquotation_scope} -= 1 if $ast->type() eq "syntaxquotation";
      return $list;
    };
    return $ast;
  }

  sub _eval {
    my $self = shift;
    my $ast = shift;
    if($ast->type() eq "list") {
      if($ast->size() == 0) {
        return $ast;
      };
      my $f = $self->_eval($ast->first());
      if($f->type() eq "symbol") {
        my $fn = $f->value();
        if($fn eq "def") {
          $ast->error("def expects 2 arguments") if $ast->size() != 3;
          my $name = $ast->second()->value();
          my $value = $self->_eval($ast->third());
          $self->new_var($name, $value);
        } elsif($fn eq "fn") {
          $ast->error("fn expects >= 3 arguments") if $ast->size() < 3;
          my $args = $ast->second();
          $ast->error("fn expects [arg ...] as formal argument list") if $args->type() ne "vector";
          my $i = 0;
          foreach my $arg (@{$args->value()}) {
            $arg->error("formal argument should be a symbol") if $arg->type() ne "symbol";
            if($arg->value() eq "&"
               and ($args->size() != $i + 2 or $args->value()->[$i+1]->value() eq "&")) {
              $arg->error("only 1 non-& should follow &");
            };
            $i ++;
          }
          my $nast = CljPerl::Atom->new("function");
          $nast->value($ast);
	  $nast->{context} = \%{$self->current_scope()};
          return $nast;
        } elsif($fn eq "defmacro") {
          $ast->error("defmacro expects >= 4 arguments") if $ast->size() < 4;
	  my $name = $ast->second()->value();
          my $args = $ast->third();
          $ast->error("defmacro expect [arg ...] as formal argument list") if $args->type() ne "vector";
          my $i = 0;
          foreach my $arg (@{$args->value()}) {
            $arg->error("formal argument should be a symbol") if $arg->type() ne "symbol";
            if($arg->value() eq "&" 
               and ($args->size() != $i + 2 or $args->value()->[$i+1]->value() eq "&")) {
              $arg->error("only 1 non-& should follow &");
            };
            $i ++;
          }
          my $nast = CljPerl::Atom->new("macro");
          $nast->value($ast);
	  $nast->{context} = \%{$self->current_scope()};
          $self->new_var($name, $nast);
          return $nast;
        } elsif($fn eq "require") {
          $ast->error("require expects 1 argument") if $ast->size() != 2;
          my $m = $ast->second();
          $ast->error("require expects a string") if $m->type() ne "string";
          $self->load($m->value());
        } elsif($fn =~ /^\.(\S*)$/) {
          my $ns = $1;
          $ast->error(". expects > 1 arguments") if $ast->size() < 2;
          my $perl_func = $ast->second()->value();
          if($perl_func eq "require") {
            $ast->error(". require expects 1 argument") if $ast->size() != 3;
            my $m = $ast->third();
            $ast->error(". require expects a string") if $m->type() ne "string";
            require $m->value();
          } else {
            $ns = "CljPerl" if ! defined $ns or $ns eq "";
            $perl_func = $ns . "::" . $perl_func;
            my @rest = $ast->slice(2 .. $ast->size()-1);
            my $args = ();
            foreach my $r (@rest) {
              push @{$args}, $r->value();
            };
            my $res = $perl_func->(@{$args});
            return $res;
          }
        } elsif($fn eq "println") {
          $ast->error("println expects 1 argument") if $ast->size() != 2;
          print CljPerl::Printer::to_string($self->_eval($ast->second())) . "\n";
	};
      } elsif($f->type() eq "function") {
        my $scope = $f->{context};
        $f = $f->value();
        my $fargs = $f->second();
	my @rargs = $ast->slice(1 .. $ast->size()-1);
	#$ast->error("real arguments mismatch with formal arguments") if $fargs->size() != scalar @rargs;
        my @rrargs = ();
        foreach my $arg (@rargs) {
          push @rrargs, $self->_eval($arg);
        };
	$self->push_scope($scope);
        my $rest_args = undef;
        my $i = 0;
	for($i=0; $i < scalar @{$fargs->value()}; $i++) {
          my $name = $fargs->value()->[$i]->value();
          $ast->error("real arguments mismatch with formal arguments") if $i > scalar @rrargs;
          if($name eq "&"){
            $i++;
            $name = $fargs->value()->[$i]->value();
            $rest_args = CljPerl::Seq->new("list");
            $self->new_var($name, $rest_args);
          } else {
	    $self->new_var($name, $rrargs[$i]);
          }
        };
        if(defined $rest_args){
          $i -= 2;
          for(; $i < scalar @rrargs; $i ++) {
            $rest_args->append($rrargs[$i]);
          }
        };
	my @body = $f->slice(2 .. $f->size()-1);
	my $res;
	foreach my $b (@body){
          $res = $self->_eval($b);
	};
	$self->pop_scope();
	return $res;
      } elsif($f->type() eq "macro") {
        my $scope = $f->{context};
        $f = $f->value();
        my $fargs = $f->third();
	my @rargs = $ast->slice(1 .. $ast->size()-1);
	#$ast->error("real arguments mismatch with formal arguments") if $fargs->size() != scalar @rargs;
	$self->push_scope($scope);
        my $rest_args = undef;
        my $i = 0;
        for($i=0; $i < scalar @{$fargs->value()}; $i++) {
          my $name = $fargs->value()->[$i]->value();
          $ast->error("real arguments mismatch with formal arguments") if $i > scalar @rargs;
          if($name eq "&"){
            $i++;
            $name = $fargs->value()->[$i]->value();
            $rest_args = CljPerl::Seq->new("list");
            $self->new_var($name, $rest_args);
          } else {
            $self->new_var($name, $rargs[$i]);
          }
        };
        if(defined $rest_args){
          $i -= 2;
          for(; $i < scalar @rargs; $i ++) {
            $rest_args->append($rargs[$i]);
          }
        };
	my @body = $f->slice(3 .. $f->size()-1);
	my $res;
	foreach my $b (@body){
          $res = $self->_eval($b);
	};
	$self->pop_scope();
	return $self->_eval($res);
      } else {
        $ast->error("expect a function or function name");
      };
    } elsif($ast->type() eq "symbol") {
      return $self->bind($ast);
    } elsif($ast->type() eq "syntaxquotation") {
      return $self->bind($ast);
    };
    return $ast;
  }
1;
