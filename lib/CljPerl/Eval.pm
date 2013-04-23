package CljPerl::Eval;

#  use strict;
  use warnings;
  use CljPerl::Reader;
  use CljPerl::Var;
  use CljPerl::Printer;
  use File::Spec;
  use File::Basename;

  sub new {
    my $class = shift;
    my @scopes = ({});
    my @file_stack = ();
    my $self = {class=>$class,
                scopes=>\@scopes,
                loaded_files=>{},
                file_stack=>\@file_stack,
                quotation_scope=>0,
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

  sub current_file {
    my $self = shift;
    my $sd = scalar @{$self->{file_stack}};
    if($sd == 0) {
      return ".";
    } else {
      return ${$self->{file_stack}}[$sd-1];
    }
  }

  sub load {
    my $self = shift;
    my $file = shift;
    if($file =~ /^[^\/]/){
      $file = dirname($self->current_file()) . "/$file";
    };
    return 1 if exists $self->{loaded_files}->{$file};
    $self->{loaded_files}->{$file} = 1;
    push @{$self->{file_stack}}, $file;
    my $reader = CljPerl::Reader->new();
    $reader->read_file($file);
    $reader->ast()->each(sub {$self->_eval($_[0])});
    pop @{$self->{file_stack}};
    return 1;
  }

  sub eval {
    my $self = shift;
    my $str = shift;
    my $reader = CljPerl::Reader->new();
    $reader->read_string($str);
    my $res = undef;
    $reader->ast()->each(sub {$res = $self->_eval($_[0])});
    return $res;
  }

  our $builtin_funcs = {
                  "eval"=>1,
                  def=>1,
                  "set!"=>1,
                  fn=>1,
		  defmacro=>1,
                  list=>1,
                  car=>1,
                  cdr=>1,
                  cons=>1,
                  "if"=>1,
                  "while"=>1,
                  "length"=>1,
                  "!"=>1,
                  "+"=>1,
                  "-"=>1,
                  "*"=>1,
                  "/"=>1,
                  "%"=>1,
                  "=="=>1,
                  "!="=>1,
                  ">"=>1,
                  ">="=>1,
                  "<"=>1,
                  "<="=>1,
                  "."=>1,
                  "eq"=>1,
                  "ne"=>1,
                  "equal"=>1,
                  "require"=>1,
	          println=>1};

  our $empty_list = CljPerl::Seq->new("list");
  our $true = CljPerl::Atom->new("bool", "true");
  our $false = CljPerl::Atom->new("bool", "false");
  our $nil = CljPerl::Atom->new("nil", "nil");

  sub bind {
    my $self = shift;
    my $ast = shift;
    if($ast->type() eq "symbol" and $ast->value() eq "true") {
      return $true;
    } elsif($ast->type() eq "symbol" and $ast->value() eq "false") {
      return $false;
    } elsif($ast->type() eq "symbol" and $ast->value() eq "nil") {
      return $nil;
    } elsif(($ast->type() eq "symbol" and $self->{syntaxquotation_scope} == 0
        and $self->{quotation_scope} == 0) or
       ($ast->type() eq "dequotation" and $self->{syntaxquotation_scope} > 0)) {
      $ast->error("dequotation should be in syntax quotation scope")
        if ($ast->type() eq "dequotation" and $self->{syntaxquotation_scope} == 0);
      my $name = $ast->value();
      if($ast->type() eq "dequotation" and $ast->value() =~ /^@(\S+)$/) {
        $name = $1;
      }
      return $ast if exists $builtin_funcs->{$name} or $name =~ /^\.\S+$/;
      my $var = $self->var($name);
      $ast->error("unbound symbol") if !defined $var;
      return $var->value();
    } elsif($ast->type() eq "symbol"
            and $self->{quotation_scope} > 0) {
      my $q = CljPerl::Atom->new("quotation", $ast->value());
      return $q;
    } elsif($ast->class() eq "Seq") {
      return $empty_list if $ast->type eq "list" and $ast->size() == 0;
      $self->{syntaxquotation_scope} += 1 if $ast->type() eq "syntaxquotation";
      $self->{quotation_scope} += 1 if $ast->type() eq "quotation";
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
      $self->{quotation_scope} -= 1 if $ast->type() eq "quotation";
      return $list;
    };
    return $ast;
  }

  sub _eval {
    my $self = shift;
    my $ast = shift;
    if($ast->type() eq "list") {
      if($ast->size() == 0) {
        return $empty_list;
      };
      my $f = $self->_eval($ast->first());
      if($f->type() eq "symbol") {
	return $self->builtin($ast);
      } elsif($f->type() eq "keyword") {
        $ast->error("map accessor expects >= 1 arguments") if $ast->size() == 1;
        my $m = $self->_eval($ast->second());
        $ast->error("map accessor expects a map as the first arguments") if $m->type() ne "map";
        if($ast->size() == 2) {
          return $m->value()->{$f->value()};
        } elsif($ast->size() == 3) {
          $m->value()->{$f->value()} = $self->_eval($ast->third());
          return $m->value()->{$f->value()};
        } else {
          $ast->error("map accessor expects <= 2 arguments");
        }
      } elsif($f->type() eq "number") {
        $ast->error("vector accessor expects >= 1 arguments") if $ast->size() == 1;
        my $m = $self->_eval($ast->second());
        $ast->error("vector accessor expects a vector as the first arguments") if $m->type() ne "vector";
        $ast->error("index is bigger than vector size") if $f->value() >= scalar @{$m->value()};
        if($ast->size() == 2) {
          return $m->value()->[$f->value()];
        } elsif($ast->size() == 3) {
          $m->value()->[$f->value()] = $self->_eval($ast->third());
          return $m->value()->[$f->value()];
        } else {
          $ast->error("vector accessor expects <= 2 arguments");
        }
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
    } elsif($ast->type() eq "quotation") {
      return $self->bind($ast);
    } elsif($ast->class() eq "Seq" and $ast->type() eq "vector") {
      my $v = CljPerl::Atom->new("vector");
      my @vv = ();
      foreach my $i (@{$ast->value()}) {
        push @vv, $self->_eval($i);
      }
      $v->value(\@vv);
      return $v;
    } elsif($ast->class() eq "Seq" and $ast->type() eq "map") {
      my $m = CljPerl::Atom->new("map");
      my %mv = ();
      my $n = scalar @{$ast->value()};
      $ast->error("map should have even number of items") if ($n%2) != 0;
      for(my $i=0; $i<$n; $i+=2) {
        my $k = $self->_eval($ast->value()->[$i]);
        $ast->error("map expect keyword or symbol as key")
          if ($k->type() ne "keyword"
              and $k->type() ne "symbol");
        my $v = $self->_eval($ast->value()->[$i+1]);
        $mv{$k->value()} = $v;
      };
      $m->value(\%mv);
      return $m;
    };
    return $ast;
  }

  sub builtin {
    my $self = shift;
    my $ast = shift;
    my $f = $ast->first();
    my $fn = $f->value();
    if($fn eq "eval") {
      $ast->error("eval expects 1 argument1") if $ast->size() != 2;
      my $s = $ast->second();
      $ast->error("eval expects 1 string as argument") if $s->type() ne "string";
      return $self->eval($s->value());
    } elsif($fn eq "def" or $fn eq "set!") {
      $ast->error($fn . " expects 2 arguments") if $ast->size() != 3;
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
      my $nast = CljPerl::Atom->new("function", $ast);
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
      my $nast = CljPerl::Atom->new("macro", $ast);
      $nast->{context} = \%{$self->current_scope()};
      $self->new_var($name, $nast);
      return $nast;
    } elsif($fn eq "require") {
      $ast->error("require expects 1 argument") if $ast->size() != 2;
      my $m = $self->_eval($ast->second());
      $ast->error("require expects a string") if $m->type() ne "string";
      $self->load($m->value());
    } elsif($fn eq "list") {
      return $emtpy_list if $ast->size() == 1;
      my @vs = $ast->slice(1 .. $ast->size()-1);
      my $r = CljPerl::Seq->new("list");
      foreach my $i (@vs) {
        $r->append($self->_eval($i));
      };
      return $r;
    } elsif($fn eq "car") {
      $ast->error("car expects 1 argument") if $ast->size() != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("car expects 1 list as argument") if $v->type() ne "list";
      my $fv = $v->first();
      return $fv;
    } elsif($fn eq "cdr") {
      $ast->error("cdr expects 1 argument") if $ast->size() != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("cdr expects 1 list as argument") if $v->type() ne "list";
      return $empty_list if($v->size()==0);
      my @vs = $v->slice(1 .. $v->size()-1);
      my $r = CljPerl::Seq->new("list");
      $r->value(\@vs);
      return $r;
    } elsif($fn eq "cons") {
      $ast->error("cons expects 2 arguments") if $ast->size() != 3;
      my $fv = $self->_eval($ast->second());
      my $rvs = $self->_eval($ast->third());
      $ast->error("cons expects 1 list as the second argument") if $rvs->type() ne "list";
      my @vs = ();
      @vs = $rvs->slice(0 .. $rvs->size()-1) if $rvs->size() > 0;
      unshift @vs, $fv;
      my $r = CljPerl::Seq->new("list");
      $r->value(\@vs);
      return $r;
    } elsif($fn eq "if") {
      $ast->error("if expects 2 or 3 arguments") if $ast->size() > 4 or $ast->size() < 3;
      my $cond = $self->_eval($ast->second());
      $ast->error("if expects a bool as the first argument") if $cond->type() ne "bool";
      if($cond->value() eq "true") {
        return $self->_eval($ast->third());
      } elsif($ast->size() == 4) {
        return $self->_eval($ast->fourth());
      } else {
        return $nil; 
      };
    } elsif($fn eq "while") {
      $ast->error("while expects >= 2 arguments") if $ast->size() < 3;
      my $cond = $self->_eval($ast->second());
      $ast->error("while expects a bool as the first argument") if $cond->type() ne "bool";
      my $res = $nil;
      my @body = $ast->slice(2 .. $ast->size()-1);
      while ($cond->value() eq "true") {
        foreach my $i (@body) {
          $res = $self->_eval($i);
        }
        $cond = $self->_eval($ast->second());
      }
      return $res;
    } elsif($fn =~ /^(\+|\-|\*|\/|\%)$/) {
      $ast->error($fn . " expects 2 arguments") if $ast->size() != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects number as arguments") if $v1->type() ne "number" or $v2->type() ne "number";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = CljPerl::Atom->new("number", eval("$vv1 $fn $vv2"));
      return $r;
    } elsif($fn =~ /^(==|>|<|>=|<=|!=)$/) {
      $ast->error($fn . " expects 2 arguments") if $ast->size() != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects number as arguments") if $v1->type() ne "number" or $v2->type() ne "number";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = eval("$vv1 $fn $vv2");
      if($r){
        return $true;
      } else {
        return $false;
      }
    } elsif($fn =~ /^(eq|ne)$/) {
      $ast->error($fn . " expects 2 arguments") if $ast->size() != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects string as arguments") if $v1->type() ne "string" or $v2->type() ne "string";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = eval("'$vv1' $fn '$vv2'");
      if($r){
        return $true;
      } else {
        return $false;
      }
    } elsif($fn eq "equal") {
      $ast->error($fn . " expects 2 arguments") if $ast->size() != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      my $r = 0;
      if($v1->type() ne $v2->type()) {
        $r = 0;
      } elsif(($v1->type() eq "string" and $v2->type() eq "string")
              or ($v1->type() eq "keyword" and $v2->type() eq "keyword")
              or ($v1->type() eq "quotation" and $v2->type() eq "quotation")){
        $r = $v1->value() eq $v2->value();
      } elsif($v1->type() eq "number" and $v2->type() eq "number"){
        $r = $v1->value() == $v2->value();
      } else {
        $r = $v1->value() == $v2->value();
      };
      if($r){
        return $true;
      } else {
        return $false;
      };
    } elsif($fn eq "!") {
      $ast->error("! expects 1 argument") if $ast->size() != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("while expects a bool as the first argument") if $v->type() ne "bool";
      if($v->value() eq "true") {
        return $false;
      } else {
        return $true;
      };
    } elsif($fn eq "length") {
      $ast->error("length expects 1 argument") if $ast->size() != 2;
      my $v = $self->_eval($ast->second());
      my $r = CljPerl::Atom->new("number", 0);
      if($v->type() eq "string"){
        $r->value(length($v->value()));
      } elsif($v->type() eq "list" or $v->type() eq "vector"){
        $r->value(scalar @{$v->value()});
      } elsif($v->type() eq "map") {
        $r->value(scalar %{$v->value()});
      } else {
        $ast->error("unexpected type of argument for length");
      };
      return $r;
    } elsif($fn =~ /^\.(\S*)$/) {
      my $ns = $1;
      $ast->error(". expects > 1 arguments") if $ast->size() < 2;
      $ast->error(". expects a symbol or keyword or stirng as the first argument")
        if ($ast->second()->type() ne "symbol"
            and $ast->second()->type() ne "keyword"
            and $ast->second()->type() ne "string");
      my $perl_func = $ast->second()->value();
      if($perl_func eq "require") {
        $ast->error(". require expects 1 argument") if $ast->size() != 3;
        my $m = $self->_eval($ast->third());
        $ast->error(". require expects a string") if $m->type() ne "string";
        require $m->value();
      } else {
        $ns = "CljPerl" if ! defined $ns or $ns eq "";
        $perl_func = $ns . "::" . $perl_func;
        my @rest = $ast->slice(2 .. $ast->size()-1);
        my $args = ();
        foreach my $r (@rest) {
          push @{$args}, $self->_eval($r)->value();
        };
        my $res = &wrap_value($ast, \$perl_func->(@{$args}));
        return $res;
      }
    } elsif($fn eq "println") {
      $ast->error("println expects 1 argument") if $ast->size() != 2;
      print CljPerl::Printer::to_string($self->_eval($ast->second())) . "\n";
      return $nil;
    };
  
    return $ast;
  }
 
  sub wrap_value {
    my $ast = shift;
    my $v = shift;
    if(ref($v) eq "SCALAR") {
      return CljPerl::Atom->new("string", ${$v});
    } elsif(ref($v) eq "HASH") {
      return CljPerl::Atom->new("map", \%{$v});
    } elsif(ref($v) eq "ARRAY") {
      return CljPerl::Atom->new("vector", \@{$v});
    } else {
      $ast->error("expect a reference of scalar or hash or array");
    };
  } 

1;
