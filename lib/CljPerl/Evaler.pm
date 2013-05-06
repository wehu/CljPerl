package CljPerl::Evaler;

#  use strict;
  use warnings;
  use CljPerl::Reader;
  use CljPerl::Var;
  use CljPerl::Printer;
  use File::Spec;
  use File::Basename;

  our $VERSION = '0.09';

  our $namespace_key = "0namespace0";

  sub new {
    my $class = shift;
    my @default_namespace = ();
    my @scopes = ({$namespace_key=>\@default_namespace});
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
    my %c = %{$context};
    my @ns = @{$c{$namespace_key}};
    $c{$namespace_key} = \@ns;
    unshift @{$self->scopes()}, \%c;
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

  sub push_namespace {
    my $self = shift;
    my $namespace = shift;
    my $scope = $self->current_scope();
    unshift @{$scope->{$namespace_key}}, $namespace;
  }

  sub pop_namespace {
    my $self = shift;
    my $scope = $self->current_scope();
    shift @{$scope->{$namespace_key}};
  }

  sub current_namespace {
    my $self = shift;
    my $scope = $self->current_scope();
    my $namespace = @{$scope->{$namespace_key}}[0];
    return "" if(!defined $namespace);
    return $namespace;
  }

  sub new_var {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    my $scope = $self->current_scope();
    $name = $self->current_namespace() . "#" . $name;
    $scope->{$name} = CljPerl::Var->new($name, $value);
  }

  sub var {
    my $self = shift;
    my $name = shift;
    my $scope = $self->current_scope();
    if(exists $scope->{$name}) {
      return $scope->{$name};
    } elsif(exists $scope->{$self->current_namespace() . "#" . $name}){
      return $scope->{$self->current_namespace() . "#" . $name};
    } elsif(exists $scope->{"#" . $name}) {
      return $scope->{"#" . $name};
    };
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

  sub search_file {
    my $self = shift;
    my $file = shift;
    foreach my $ext ("", ".clp") {
      if(-f "$file$ext") {
        return "$file$ext";
      } elsif(-f dirname($self->current_file()) . "/$file$ext") {
        return dirname($self->current_file()) . "/$file$ext";
      } elsif(-f $file . $ext) {
        return $file . $ext;
      };
      foreach my $p (@INC) {
        if(-f "$p/$file$ext") {
          return "$p/$file$ext";
        };
      }
    }
    CljPerl::Logger::error("cannot find " . $file); 
  }

  sub load {
    my $self = shift;
    my $file = shift;
    CljPerl::Logger::error("cannot require file " . $file . " in non-global scope")
      if scalar @{$self->scopes()} > 1;
    $file = File::Spec->rel2abs($self->search_file($file));
    return 1 if exists $self->{loaded_files}->{$file};
    $self->{loaded_files}->{$file} = 1;
    push @{$self->{file_stack}}, $file;
    my $res = $self->read($file);
    pop @{$self->{file_stack}};
    return $res;
  }

  sub read {
    my $self = shift;
    my $file = shift;
    my $reader = CljPerl::Reader->new();
    $reader->read_file($file);
    #my $scopes_size = scalar @{$self->{scopes}};
    #my @backup_scopes = @{$self->{scopes}}[0 .. $scopes_size-2];
    #my @nss = ($self->{scopes}->[$scopes_size-1]);
    #$self->{scopes} = \@nss;
    my $res = undef;
    $reader->ast()->each(sub {$res = $self->_eval($_[0])});
    #$scopes_size = scalar @{$self->{scopes}};
    #$self->{scopes} = \@backup_scopes;
    #push @{$self->{scopes}}, $self->{scopes}->[$scopes_size-1];
    return $res;
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
                  syntax=>1,
                  def=>1,
                  "set!"=>1,
                  let=>1,
                  fn=>1,
		  defmacro=>1,
                  "gen-sym"=>1,
                  list=>1,
                  car=>1,
                  cdr=>1,
                  cons=>1,
                  "if"=>1,
                  "while"=>1,
                  "begin"=>1,
                  "length"=>1,
                  "object-id"=>1,
                  "type"=>1,
                  "perlobj-type"=>1,
                  "meta"=>1,
                  "apply"=>1,
                  append=>1,
                  "keys"=>1,
                  "namespace-begin"=>1,
                  "namespace-end"=>1,
                  "perl->clj"=>1,
                  "clj->string"=>1,
                  "!"=>1,
                  "not"=>1,
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
                  "->"=>1,
                  "eq"=>1,
                  "ne"=>1,
		  "and"=>1,
		  "or"=>1,
                  "equal"=>1,
                  "require"=>1,
		  "read"=>1,
	          println=>1, 
                  "xml-name"=>1,
                  "trace-vars"=>1};

  our $empty_list = CljPerl::Seq->new("list");
  our $true = CljPerl::Atom->new("bool", "true");
  our $false = CljPerl::Atom->new("bool", "false");
  our $nil = CljPerl::Atom->new("nil", "nil");

  sub bind {
    my $self = shift;
    my $ast = shift;
    my $class = $ast->class();
    my $type  = $ast->type();
    my $value = $ast->value();
    if($type eq "symbol" and $value eq "true") {
      return $true;
    } elsif($type eq "symbol" and $value eq "false") {
      return $false;
    } elsif($type eq "symbol" and $value eq "nil") {
      return $nil;
    } elsif($type eq "accessor") {
      return CljPerl::Atom->new("accessor", $self->bind($value));
    } elsif($type eq "sender") {
      return CljPerl::Atom->new("sender", $self->bind($value));
    } elsif($type eq "syntaxquotation" or $type eq "quotation") {
      $self->{syntaxquotation_scope} += 1 if $type eq "syntaxquotation";
      $self->{quotation_scope} += 1 if $type eq "quotation";
      my $r = $self->bind($value);
      $self->{syntaxquotation_scope} -= 1 if $type eq "syntaxquotation";
      $self->{quotation_scope} -= 1 if $type eq "quotation";
      return $r;
    } elsif(($type eq "symbol" and $self->{syntaxquotation_scope} == 0
        and $self->{quotation_scope} == 0) or
       ($type eq "dequotation" and $self->{syntaxquotation_scope} > 0)) {
      $ast->error("dequotation should be in syntax quotation scope")
        if ($type eq "dequotation" and $self->{syntaxquotation_scope} == 0);
      my $name = $value;
      if($type eq "dequotation" and $value =~ /^@(\S+)$/) {
        $name = $1;
      }
      return $ast if exists $builtin_funcs->{$name} or $name =~ /^(\.|->)\S+$/;
      my $var = $self->var($name);
      $ast->error("unbound symbol") if !defined $var;
      return $var->value();
    } elsif($type eq "symbol"
            and $self->{quotation_scope} > 0) {
      my $q = CljPerl::Atom->new("quotation", $value);
      return $q;
    } elsif($class eq "Seq") {
      return $empty_list if $type eq "list" and $ast->size() == 0;
      my $list = CljPerl::Seq->new("list");
      $list->type($type);
      foreach my $i (@{$value}) {
        if($i->type() eq "dequotation" and $i->value() =~ /^@/){
          my $dl = $self->bind($i);
          $i->error("~@ should be given a list but got " . $dl->type()) if $dl->type() ne "list";
          foreach my $di (@{$dl->value()}){
            $list->append($di);
          };
        } else {
          $list->append($self->bind($i));
        }
      }
      return $list;
    };
    return $ast;
  }

  sub _eval {
    my $self = shift;
    my $ast = shift;
    my $class = $ast->class();
    my $type  = $ast->type();
    my $value = $ast->value();
    if($type eq "list") {
      my $size = $ast->size();
      if($size == 0) {
        return $empty_list;
      };
      my $f = $self->_eval($ast->first());
      my $ftype = $f->type();
      my $fvalue = $f->value();
      if($ftype eq "symbol") {
	return $self->builtin($f, $ast);
      } elsif($ftype eq "key accessor") {
        $ast->error("key accessor expects >= 1 arguments") if $size == 1;
        my $m = $self->_eval($ast->second());
        my $mtype = $m->type();
        my $mvalue = $m->value();
        $ast->error("key accessor expects a map or meta as the first arguments but got " . $mtype)
           if $mtype ne "map" and $mtype ne "meta";
        if($size == 2) {
          #$ast->error("key " . $fvalue . " does not exist")
          return $nil  if ! exists $mvalue->{$fvalue};
          return $mvalue->{$fvalue};
        } elsif($size == 3) {
          my $v = $self->_eval($ast->third()); 
          if($v->type() eq "nil"){
            delete $mvalue->{$fvalue};
            return $nil;
          } else {
            $mvalue->{$fvalue} = $v;
            return $mvalue->{$fvalue};
          };
        } else {
          $ast->error("key accessor expects <= 2 arguments");
        }
      } elsif($ftype eq "index accessor") {
        $ast->error("index accessor expects >= 1 arguments") if $size == 1;
        my $v = $self->_eval($ast->second());
        my $vtype = $v->type();
        my $vvalue = $v->value();
        $ast->error("index accessor expects a vector or list or xml as the first arguments but got " . $vtype)
           if $vtype ne "vector" and $vtype ne "list"
              and $vtype ne "xml";
        $ast->error("index is bigger than size") if $fvalue >= scalar @{$vvalue};
        if($size == 2) {
          return $vvalue->[$fvalue];
        } elsif($size == 3) {
          $vvalue->[$fvalue] = $self->_eval($ast->third());
          return $vvalue->[$fvalue];
        } else {
          $ast->error("index accessor expects <= 2 arguments");
        }
      } elsif($ftype eq "function") {
        my $scope = $f->{context};
        my $fn = $fvalue;
        my $fargs = $fn->second();
	my @rargs = $ast->slice(1 .. $size-1);
        my @rrargs = ();
        foreach my $arg (@rargs) {
          push @rrargs, $self->_eval($arg);
        };
	$self->push_scope($scope);
        my $rest_args = undef;
        my $i = 0;
        my $fargsvalue = $fargs->value();
        my $fargsn = scalar @{$fargsvalue};
        my $rrargsn = scalar @rrargs;
	for($i=0; $i < $fargsn; $i++) {
          my $name = $fargsvalue->[$i]->value();
          if($name eq "&"){
            $i++;
            $name = $fargsvalue->[$i]->value();
            $rest_args = CljPerl::Seq->new("list");
            $self->new_var($name, $rest_args);
          } else {
            $ast->error("real arguments < formal arguments") if $i >= $rrargsn;
	    $self->new_var($name, $rrargs[$i]);
          }
        };
        if(defined $rest_args){
          $i -= 2;
          for(; $i < $rrargsn; $i ++) {
            $rest_args->append($rrargs[$i]);
          }
        } else {
          $ast->error("real arguments > formal arguments") if $i < $rrargsn;
        };
	my @body = $fn->slice(2 .. $fn->size()-1);
	my $res;
	foreach my $b (@body){
          $res = $self->_eval($b);
	};
	$self->pop_scope();
	return $res;
      } elsif($ftype eq "perlfunction") {
        my $meta = undef;
        $meta = $self->_eval($ast->second()) if defined $ast->second() and $ast->second()->type() eq "meta";
        my $perl_func = $f->value();
        my @args = $ast->slice((defined $meta ? 2 : 1) .. $size-1);
        return $self->perlfunc_call($perl_func, $meta, \@args);
      } elsif($ftype eq "macro") {
        my $scope = $f->{context};
        my $fn = $f->value();
        my $fargs = $fn->third();
	my @rargs = $ast->slice(1 .. $ast->size()-1);
	$self->push_scope($scope);
        my $rest_args = undef;
        my $i = 0;
        my $fargsvalue = $fargs->value();
        my $fargsn = scalar @{$fargsvalue};
        my $rargsn = scalar @rargs;
        for($i=0; $i < $fargsn; $i++) {
          my $name = $fargsvalue->[$i]->value();
          if($name eq "&"){
            $i++;
            $name = $fargsvalue->[$i]->value();
            $rest_args = CljPerl::Seq->new("list");
            $self->new_var($name, $rest_args);
          } else {
            $ast->error("real arguments < formal arguments") if $i >= $rargsn;
            $self->new_var($name, $rargs[$i]);
          }
        };
        if(defined $rest_args){
          $i -= 2;
          for(; $i < $rargsn; $i ++) {
            $rest_args->append($rargs[$i]);
          }
        } else {
          $ast->error("real arguments > formal arguments") if $i < $rargsn;
        };
	my @body = $fn->slice(3 .. $fn->size()-1);
	my $res;
	foreach my $b (@body){
          $res = $self->_eval($b);
	};
	$self->pop_scope();
	return $self->_eval($res);
      } else {
        $ast->error("expect a function or function name or index/key accessor");
      };
    } elsif($type eq "accessor") {
      my $av = $self->_eval($value);
      my $a = CljPerl::Atom->new("unknown", $av->value());
      my $at = $av->type();
      if($at eq "number") {
        $a->type("index accessor");
      } elsif($at eq "string" or $at eq "keyword") {
        $a->type("key accessor");
      } else {
        $ast->error("unsupport type " . $at . " for accessor but got " . $at);
      }
      return $a;
    } elsif($type eq "sender") {
      my $sn = $self->_eval($value);
      $ast->error("sender expects a string or keyword but got " . $type)
        if $sn->type() ne "string"
           and $sn->type() ne "keyword";
      my $s = CljPerl::Atom->new("symbol", $sn->value());
      return $self->bind($s);
    } elsif($type eq "symbol") {
      return $self->bind($ast);
    } elsif($type eq "syntaxquotation") {
      return $self->bind($ast);
    } elsif($type eq "quotation") {
      return $self->bind($ast);
    } elsif($class eq "Seq" and $type eq "vector") {
      my $v = CljPerl::Atom->new("vector");
      my @vv = ();
      foreach my $i (@{$value}) {
        push @vv, $self->_eval($i);
      }
      $v->value(\@vv);
      return $v;
    } elsif($class eq "Seq" and ($type eq "map" or $type eq "meta")) {
      my $m = CljPerl::Atom->new("map");
      my %mv = ();
      my $n = scalar @{$value};
      $ast->error($type . " should have even number of items") if ($n%2) != 0;
      for(my $i=0; $i<$n; $i+=2) {
        my $k = $self->_eval($value->[$i]);
        $ast->error($type . " expects keyword or string as key but got " . $k->type())
          if ($k->type() ne "keyword"
              and $k->type() ne "string");
        my $v = $self->_eval($value->[$i+1]);
        $mv{$k->value()} = $v;
      };
      $m->value(\%mv);
      $m->type("meta") if $type eq "meta";
      return $m;
    } elsif($class eq "Seq" and $type eq "xml") {
      my $size = $ast->size();
      $ast->error("xml expects >= 1 arguments") if $size == 0;
      my $first = $ast->first();
      my $firsttype = $first->type(); 
      if($firsttype ne "symbol") {
        $first = $self->_eval($first);
        $firsttype = $first->type();
      };
      $ast->error("xml expects a symbol or string or keyword as name but got " . $firsttype)
        if $firsttype ne "symbol"
           and $firsttype ne "string"
           and $firsttype ne "keyword";
      my @items = ();
      my $xml = CljPerl::Atom->new("xml", \@items);
      $xml->{name} = $first->value();
      my @rest = $ast->slice(1 .. $size-1);
      foreach my $i (@rest) {
        my $iv = $self->_eval($i);
        my $it = $iv->type();
        $ast->error("xml expects string or xml or meta or list as items but got " . $it)
          if $it ne "string"
             and $it ne "xml"
             and $it ne "meta"
             and $it ne "list";
        if($it eq "meta") {
          $xml->meta($iv);
        } elsif($it eq "list") {
	  foreach my $i (@{$iv->value()}) {
            push @items, $i;
	  };
        } else {;
          push @items, $iv;
        };
      };
      return $xml;
    };
    return $ast;
  }

  sub builtin {
    my $self = shift;
    my $f = shift;
    my $ast = shift;
    my $size = $ast->size();
    #my $f = $ast->first();
    my $fn = $f->value();

    # (eval "bla bla bla")
    if($fn eq "eval") {
      $ast->error("eval expects 1 argument") if $size != 2;
      my $s = $ast->second();
      $ast->error("eval expects 1 string as argument but got " . $s->type()) if $s->type() ne "string";
      return $self->eval($s->value());
    } elsif($fn eq "syntax") {
      $ast->error("syntax expects 1 argument") if $size != 2;
      return $self->bind($ast->second());
    # (def ^{} name value)
    } elsif($fn eq "def") {
      $ast->error($fn . " expects 2 arguments") if $size > 4 or $size < 3;
      if($size == 3){
        $ast->error($fn . " expects a symbol as the first argument but got " . $ast->second()->type()) if $ast->second()->type() ne "symbol";
        my $name = $ast->second()->value();
        $ast->error($name . " is a reserved word") if exists $builtin_funcs->{$name} or $name =~ /^(\.|->)\S+$/; 
        $self->new_var($name);
        my $value = $self->_eval($ast->third());
        $self->var($name)->value($value);
        return $value;
      } else {
        my $meta = $self->_eval($ast->second());
        $ast->error($fn . " expects a meta as the first argument but got " . $meta->type()) if $meta->type() ne "meta";
        $ast->error($fn . " expects a symbol as the first argument but got " . $ast->third()->type()) if $ast->third()->type() ne "symbol";
        my $name = $ast->third()->value();
        $ast->error($name . " is a reserved word") if exists $builtin_funcs->{$name} or $name =~ /^(\.|->)\S+$/;
        $self->new_var($name);
        my $value = $self->_eval($ast->fourth());
        $value->meta($meta);
        $self->var($name)->value($value);
        return $value;
      }
    # (set! name value)
    } elsif($fn eq "set!") {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      $ast->error($fn . " expects a symbol as the first argument but got " . $ast->second()->type()) if $ast->second()->type() ne "symbol";
      my $name = $ast->second()->value();
      $ast->error("undefine variable " . $name) if !defined $self->var($name);
      my $value = $self->_eval($ast->third());
      $self->var($name)->value($value);
      return $value;
    } elsif($fn eq "let") {
      $ast->error($fn . " expects >=3 arguments") if $size < 3;
      my $vars = $ast->second();
      $ast->error($fn . " expects a list [name value ...] as the first argument") if $vars->type() ne "vector";
      my $varssize = $vars->size();
      $ast->error($fn . " expects [name value ...] pairs as the first argument") if $varssize%2 != 0;
      my $varvs = $vars->value();
      $self->push_scope($self->current_scope());
      for(my $i=0; $i < $varssize; $i+=2) {
        my $n = $varvs->[$i];
        my $v = $varvs->[$i+1];
        $ast->error($fn . " expects a symbol as name but got " . $n->type()) if $n->type() ne "symbol";
        $self->new_var($n->value(), $self->_eval($v));
      };
      my @body = $ast->slice(2 .. $size-1);
      my $res = $nil;
      foreach my $b (@body){
        $res = $self->_eval($b);
      };
      $self->pop_scope(); 
      return $res;
    # (fn [args ...] body)
    } elsif($fn eq "fn") {
      $ast->error("fn expects >= 3 arguments") if $size < 3;
      my $args = $ast->second();
      my $argstype = $args->type();
      $ast->error("fn expects [arg ...] as formal argument list") if $argstype ne "vector";
      my $argsvalue = $args->value();
      my $argssize = $args->size();
      my $i = 0;
      foreach my $arg (@{$argsvalue}) {
        $arg->error("formal argument should be a symbol but got " . $arg->type()) if $arg->type() ne "symbol";
        if($arg->value() eq "&"
           and ($argssize != $i + 2 or $argsvalue->[$i+1]->value() eq "&")) {
          $arg->error("only 1 non-& should follow &");
        };
        $i ++;
      }
      my $nast = CljPerl::Atom->new("function", $ast);
      my %c = %{$self->current_scope()};
      my @ns = @{$c{$namespace_key}};
      $c{$namespace_key} = \@ns;
      $nast->{context} = \%c;
      return $nast;
    # (defmacro name [args ...] body)
    } elsif($fn eq "defmacro") {
      $ast->error("defmacro expects >= 4 arguments") if $size < 4;
      my $name = $ast->second()->value();
      my $args = $ast->third();
      $ast->error("defmacro expect [arg ...] as formal argument list") if $args->type() ne "vector";
      my $i = 0;
      foreach my $arg (@{$args->value()}) {
        $arg->error("formal argument should be a symbol but got " . $arg->type()) if $arg->type() ne "symbol";
        if($arg->value() eq "&"
           and ($args->size() != $i + 2 or $args->value()->[$i+1]->value() eq "&")) {
          $arg->error("only 1 non-& should follow &");
        };
        $i ++;
      }
      my $nast = CljPerl::Atom->new("macro", $ast);
      my %c = %{$self->current_scope()};
      my @ns = @{$c{$namespace_key}};
      $c{$namespace_key} = \@ns;
      $nast->{context} = \%c;
      $self->new_var($name, $nast);
      return $nast;
    # (gen-sym)
    } elsif($fn eq "gen-sym") {
      $ast->error("gen-sym expects 0/1 argument") if $size > 2;
      my $s = CljPerl::Atom->new("symbol");
      if($size == 2) {
        my $pre = $self->_eval($ast->second());
        $ast->("gen-sym expects string as argument") if $pre->type ne "string"; 
        $s->value($pre->value() . $s->object_id()); 
      } else {
        $s->value($s->object_id());
      }; 
      return $s;
    # (require "filename")
    } elsif($fn eq "require") {
      $ast->error("require expects 1 argument") if $size != 2;
      my $m = $ast->second();
      if($m->type() eq "symbol" or $m->type() eq "keyword") {
      } else {
        $m = $self->_eval($m);
        $ast->error("require expects a string but got " . $m->type())
          if $m->type() ne "string";
      };
      return $self->load($m->value());
    } elsif($fn eq "read") {
      $ast->error("read expects 1 argument") if $size != 2;
      my $f = $self->_eval($ast->second());
      $ast->error("read expects a string but got " . $f->type())
        if $f->type() ne "string";
      return $self->read($f->value());
    # (list 'a 'b 'c)
    } elsif($fn eq "list") {
      return $emtpy_list if $size == 1;
      my @vs = $ast->slice(1 .. $size-1);
      my $r = CljPerl::Seq->new("list");
      foreach my $i (@vs) {
        $r->append($self->_eval($i));
      };
      return $r;
    # (car list)
    } elsif($fn eq "car") {
      $ast->error("car expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("car expects 1 list as argument but got " . $v->type()) if $v->type() ne "list";
      my $fv = $v->first();
      return $fv;
    # (cdr list)
    } elsif($fn eq "cdr") {
      $ast->error("cdr expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("cdr expects 1 list as argument but got " . $v->type()) if $v->type() ne "list";
      return $empty_list if($v->size()==0);
      my @vs = $v->slice(1 .. $v->size()-1);
      my $r = CljPerl::Seq->new("list");
      $r->value(\@vs);
      return $r;
    # (cons item list)
    } elsif($fn eq "cons") {
      $ast->error("cons expects 2 arguments") if $size != 3;
      my $fv = $self->_eval($ast->second());
      my $rvs = $self->_eval($ast->third());
      $ast->error("cons expects 1 list as the second argument but got " . $rvs->type()) if $rvs->type() ne "list";
      my @vs = ();
      @vs = $rvs->slice(0 .. $rvs->size()-1) if $rvs->size() > 0;
      unshift @vs, $fv;
      my $r = CljPerl::Seq->new("list");
      $r->value(\@vs);
      return $r;
    # (if cond true_clause false_clause)
    } elsif($fn eq "if") {
      $ast->error("if expects 2 or 3 arguments") if $size > 4 or $size < 3;
      my $cond = $self->_eval($ast->second());
      $ast->error("if expects a bool as the first argument but got " . $cond->type()) if $cond->type() ne "bool";
      if($cond->value() eq "true") {
        return $self->_eval($ast->third());
      } elsif($ast->size() == 4) {
        return $self->_eval($ast->fourth());
      } else {
        return $nil; 
      };
    # (while cond body)
    } elsif($fn eq "while") {
      $ast->error("while expects >= 2 arguments") if $size < 3;
      my $cond = $self->_eval($ast->second());
      $ast->error("while expects a bool as the first argument but got " . $cond->type()) if $cond->type() ne "bool";
      my $res = $nil;
      my @body = $ast->slice(2 .. $size-1);
      while ($cond->value() eq "true") {
        foreach my $i (@body) {
          $res = $self->_eval($i);
        }
        $cond = $self->_eval($ast->second());
      }
      return $res;
    # (begin body)
    } elsif($fn eq "begin") {
      $ast->error("being expects >= 1 arguments") if $size < 2;
      my $res = $nil;
      my @body = $ast->slice(1 .. $size-1);
      foreach my $i (@body) {
        $res = $self->_eval($i);
      }
      return $res;
    # + - & / % operations
    } elsif($fn =~ /^(\+|\-|\*|\/|\%)$/) {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects number as arguments but got " . $v1->type() . " and " . $v2->type())
        if $v1->type() ne "number" or $v2->type() ne "number";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = CljPerl::Atom->new("number", eval("$vv1 $fn $vv2"));
      return $r;
    # == > < >= <= != logic operations
    } elsif($fn =~ /^(==|>|<|>=|<=|!=)$/) {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects number as arguments but got " . $v1->type() . " and " . $v2->type())
        if $v1->type() ne "number" or $v2->type() ne "number";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = eval("$vv1 $fn $vv2");
      if($r){
        return $true;
      } else {
        return $false;
      }
    } elsif($fn eq "xml-name") {
      $ast->error($fn . " expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error($fn . " expects xml as argument but got " . $v->type()) if $v->type() ne "xml"; 
      return CljPerl::Atom->new("string", $v->{name}); 
    # eq ne for string comparing
    } elsif($fn =~ /^(eq|ne)$/) {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects string as arguments but got " . $v1->type() . " and " . $v2->type())
        if $v1->type() ne "string" or $v2->type() ne "string";
      my $vv1 = $v1->value();
      my $vv2 = $v2->value();
      my $r = eval("'$vv1' $fn '$vv2'");
      if($r){
        return $true;
      } else {
        return $false;
      }
    # (equal a b)
    } elsif($fn eq "equal") {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      my $r = 0;
      if($v1->type() ne $v2->type()) {
        $r = 0;
      } elsif($v1->type() eq "string"
              or $v1->type() eq "keyword"
              or $v1->type() eq "quotation"
              or $v1->type() eq "bool"
              or $v1->type() eq "nil"){
        $r = $v1->value() eq $v2->value();
      } elsif($v1->type() eq "number"){
        $r = $v1->value() == $v2->value();
      } else {
        $r = $v1->value() eq $v2->value();
      };
      if($r){
        return $true;
      } else {
        return $false;
      };
    # (! true_or_false)
    } elsif($fn eq "!" or $fn eq "not") {
      $ast->error("!/not expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("!/not expects a bool as the first argument but got " . $v->type()) if $v->type() ne "bool";
      if($v->value() eq "true") {
        return $false;
      } else {
        return $true;
      };
    # (and/or true_or_false true_or_false)
    } elsif($fn eq "and") {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      $ast->error($fn . " expects bool as arguments but got " . $v1->type())
        if $v1->type() ne "bool";
      return $false if $v1->value() eq "false";
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects bool as arguments but got " . $v2->type())
        if $v2->type() ne "bool";
      if($v2->value() eq "true") {
        return $true;
      } else {
        return $false;
      };
    } elsif($fn eq "or") {
      $ast->error($fn . " expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      $ast->error($fn . " expects bool as arguments but got " . $v1->type())
        if $v1->type() ne "bool";
      return $true if $v1->value() eq "true";
      my $v2 = $self->_eval($ast->third());
      $ast->error($fn . " expects bool as arguments but got " . $v2->type())
        if $v2->type() ne "bool";
      if($v2->value() eq "true") { 
        return $true;
      } else {
        return $false;
      };
    # (length list_or_vector_or_xml_map_or_string)
    } elsif($fn eq "length") {
      $ast->error("length expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      my $r = CljPerl::Atom->new("number", 0);
      if($v->type() eq "string"){
        $r->value(length($v->value()));
      } elsif($v->type() eq "list" or $v->type() eq "vector" or $v->type() eq "xml"){
        $r->value(scalar @{$v->value()});
      } elsif($v->type() eq "map") {
        $r->value(scalar %{$v->value()});
      } else {
        $ast->error("unexpected type " . $v->type() . " of argument for length");
      };
      return $r;
    # (append list1 list2)
    } elsif($fn eq "append") {
      $ast->error("append expects 2 arguments") if $size != 3;
      my $v1 = $self->_eval($ast->second());
      my $v2 = $self->_eval($ast->third());
      my $v1type = $v1->type();
      my $v2type = $v2->type();
      $ast->error("append expects string or list or vector as arguments but got " . $v1type . " and " . $v2type)
       if (($v1type ne $v2type)
           or ($v1type ne "string"
               and $v1type ne "list"
               and $v1type ne "vector"
               and $v1type ne "map"));
      if($v1type eq "string") {
        return CljPerl::Atom->new("string", $v1->value() . $v2->value());
      } elsif($v1type eq "list" or $v1type eq "vector") {
        my @r = ();
        push @r, @{$v1->value()};
        push @r, @{$v2->value()};
        if($v1type eq "list"){
          return CljPerl::Seq->new("list", \@r);
        } else {
          return CljPerl::Atom->new("vector", \@r);
        };
      } else {
        my %r = (%{$v1->value()}, %{$v2->value()});
        return CljPerl::Atom->new("map", \%r);
      };
    # (keys map)
    } elsif($fn eq "keys") {
      $ast->error("keys expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("keys expects map as arguments but got " . $v->type()) if $v->type() ne "map";
      my @r = ();
      foreach my $k (keys %{$v->value()}) {
        push @r, CljPerl::Atom->new("keyword", $k);
      };
      return CljPerl::Seq->new("list", \@r);
    # (namespace-begin "ns")
    } elsif($fn eq "namespace-begin") {
      $ast->error("namespace-begin expects 1 argument") if $size != 2;
      my $v = $ast->second();
      if($v->type() eq "symbol" or $v->type() eq "keyword") {
      } else {
        $v = $self->_eval($v);
        $ast->error("namespace-begin expects string as argument but got " . $v->type())
          if $v->type() ne "string";
      };
      $self->push_namespace($v->value());
      return $v;
    # (namespace-end)
    } elsif($fn eq "namespace-end") {
      $ast->error("namespace-end expects 0 argument") if $size != 1;
      $self->pop_namespace();
      return $nil;
    # (object-id obj)
    } elsif($fn eq "object-id") {
      $ast->error("object-id expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      return CljPerl::Atom->new("string", $v->object_id());
    # (type obj)
    } elsif($fn eq "type") {
      $ast->error("type expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      return CljPerl::Atom->new("string", $v->type());
     # (perlobj-type obj)
    } elsif($fn eq "perlobj-type") {
      $ast->error("perlobj-type expects 1 argument") if $size != 2;
      my $v = $self->_eval($ast->second());
      $ast->error("perlobj-type expects perlobject as argument but got " . $v->type()) if($v->type() ne "perlobject");
      return CljPerl::Atom->new("string", ref($v->value()));
    # (apply fn list)
    } elsif($fn eq "apply") {
      $ast->error("apply expects 2 arguments") if $size != 3;
      my $f = $self->_eval($ast->second());
      $ast->error("apply expects function as the first argument but got " . $f->type())
        if ($f->type() ne "function"
            and !($f->type() eq "symbol" and exists $builtin_funcs->{$f->value()}));
      my $l = $self->_eval($ast->third());
      $ast->error("apply expects list as the first argument but got " . $l->type()) if $l->type() ne "list";
      my $n = CljPerl::Seq->new("list");
      $n->append($f);
      foreach my $i (@{$l->value()}) {
        $n->append($i);
      }
      return $self->_eval($n);
    # (meta obj)
    } elsif($fn eq "meta") {
      $ast->error("meta expects 1 or 2 arguments") if $size < 2 or $size > 3;
      my $v = $self->_eval($ast->second());
      if($size == 3){
        my $vm = $self->_eval($ast->third());
        $ast->error("meta expects 1 meta data as the second arguments but got " . $vm->type()) if $vm->type() ne "meta";
        $v->meta($vm);
      }
      my $m = $v->meta();
      $ast->error("no meta data in " . CljPerl::Printer::to_string($v)) if !defined $m;
      return $m;
    } elsif($fn eq "clj->string") {
      $ast->error("clj->string expects 1 argument") if $size != 2;
     my $v = $self->_eval($ast->second());
      return CljPerl::Atom->new("string", CljPerl::Printer::to_string($v));
    # (.namespace function args...)
    } elsif($fn =~ /^(\.|->)(\S*)$/) {
      my $blessed = $1;
      my $ns = $2;
      $ast->error(". expects > 1 arguments") if $size < 2;
      $ast->error(". expects a symbol or keyword or stirng as the first argument but got " . $ast->second()->type())
        if ($ast->second()->type() ne "symbol"
            and $ast->second()->type() ne "keyword"
            and $ast->second()->type() ne "string");
      my $perl_func = $ast->second()->value();
      if($perl_func eq "require") {
        $ast->error(". require expects 1 argument") if $size != 3;
        my $m = $ast->third();
        if($m->type() eq "keyword" or $m->type() eq "symbol") {
        } elsif($m->type() eq "string") {
          $m = $self->_eval($ast->third());
        } else {
          $ast->error(". require expects a string but got " . $m->type());
        };
        my $mn = $m->value();
        $mn =~ s/::/\//g;
        foreach my $ext ("", ".pm") {
          if(-f $mn . $ext) {
            require $mn . $ext;
            return $true;
          };
          foreach my $p (@INC) {
            if(-f "$p/$mn$ext") { 
              require "$p/$mn$ext";
              return $true;
            };
          }
        }
        $ast->error("cannot find $mn");
      } else {
        $ns = "CljPerl" if ! defined $ns or $ns eq "";
        my $meta = undef;
        $meta = $self->_eval($ast->third()) if defined $ast->third() and $ast->third()->type() eq "meta";
        $perl_func = $ns . "::" . $perl_func;
        my @rest = $ast->slice((defined $meta ? 3 : 2) .. $size-1);
        unshift @rest, CljPerl::Atom->new("string", $ns) if $blessed eq "->";
        return $self->perlfunc_call($perl_func, $meta, \@rest);
      }
    # (perl->clj o)
    } elsif($fn eq "perl->clj") {
      $ast->error("perl->clj expects 1 argument") if $size != 2;
      my $o = $self->_eval($ast->second());
      $ast->error("perl->clj expects perlobject as argument but got " . $o->type()) if $o->type() ne "perlobject";
      return &perl2clj($o->value());
    # (println obj)
    } elsif($fn eq "println") {
      $ast->error("println expects 1 argument") if $size != 2;
      print CljPerl::Printer::to_string($self->_eval($ast->second())) . "\n";
      return $nil;
    } elsif($fn eq "trace-vars") {
      $ast->error("trace-vars expects 0 argument") if $size != 1;
      $self->trace_vars();
      return $nil;
    };
  
    return $ast;
  }

  sub perlfunc_call {
    my $self = shift;
    my $perl_func = shift;
    my $meta = shift;
    my $rargs = shift;
    my $ret_type = "scalar";
    my @fargtypes = ();
    if(defined $meta) {
      if(exists $meta->value()->{"return"}) {
        my $rt = $meta->value()->{"return"};
        $ast->error("return expects a string or keyword but got " . $rt->type())
          if $rt->type() ne "string"
             and $rt->type() ne "keyword";
        $ret_type = $rt->value();
      };
      if(exists $meta->value()->{"arguments"}) {
        my $ats = $meta->value()->{"arguments"};
        $ast->error("arguments expect a vector but got " . $ats->type()) if $ats->type() ne "vector";
        foreach my $arg (@{$ats->value()}) {
          $ast->error("arguments expect a vector of string or keyword but got " . $arg->type())
            if $arg->type() ne "string"
               and $arg->type() ne "keyword";
          push @fargtypes, $arg->value();
        };
      };
    };
    my @args = ();
    my $i = 0;
    foreach my $arg (@{$rargs}) {
      my $pobj = $self->clj2perl($self->_eval($arg));
      if($i < scalar @fargtypes) {
        my $ft = $fargtypes[$i];
        if($ft eq "scalar") {
          push @args, $pobj;
        } elsif($ft eq "array") {
          push @args, @{$pobj};
        } elsif($ft eq "hash") {
          push @args, %{$pobj};
        } elsif($ft eq "ref") {
          push @args, \$pobj;
        } else {
          push @args, $pobj;
        };
      } else {
        if(ref($pobj) eq "ARRAY") {
          push @args, @{$pobj};
        } elsif(ref($pobj) eq "HASH") {
          push @args, %{$pobj};
        } else {
          push @args, $pobj;
        };
      };
      $i ++;
    };

    if($ret_type eq "scalar") {
      my $r = $perl_func->(@args);
      return &wrap_perlobj($r);
    } elsif($ret_type eq "ref-scalar") {
      my $r = $perl_func->(@args);
      return &wrap_perlobj(\$r);
    } elsif($ret_type eq "array") {
      my @r = $perl_func->(@args);
      return &wrap_perlobj(@r);
    } elsif($ret_type eq "ref-array") {
      my @r = $perl_func->(@args);
      return &wrap_perlobj(\@r);
    } elsif($ret_type eq "hash") {
      my %r = $perl_func->(@args);
      return &wrap_perlobj(%r);
    } elsif($ret_type eq "ref-hash") {
      my %r = $perl_func->(@args);
      return &wrap_perlobj(\%r);
    } elsif($ret_type eq "nil") {
      $perl_func->(@args);
      return $nil;
    } else {
      my $r = \$perl_func->(@args);
      return &wrap_perlobj($r);
    };

  }

  sub clj2perl {
    my $self = shift;
    my $ast = shift;
    my $type = $ast->type();
    my $value = $ast->value();
    if($type eq "string" or $type eq "number"
       or $type eq "quotation" or $type eq "keyword"
       or $type eq "perlobject") {
      return $value;
    } elsif($type eq "bool") {
      if($value eq "true") {
        return 1;
      } else {
        return 0;
      }
    } elsif($type eq "nil") {
      return undef;
    } elsif($type eq "list" or $type eq "vector") {
      my @r = ();
      foreach my $i (@{$value}) {
        push @r, $self->clj2perl($i);
      };
      return \@r;
    } elsif($type eq "map") {
      my %r = ();
      foreach my $k (keys %{$value}) {
        $r{$k} = $self->clj2perl($value->{$k});
      };
      return \%r;
    } elsif($type eq "function") {
      my $f = sub {
        my @args = @_;
        my $cljf = CljPerl::Seq->new("list");
        $cljf->append($ast);
        foreach my $arg (@args) {
          $cljf->append(&perl2clj($arg));
        };
        return $self->clj2perl($self->_eval($cljf));
      };
      return $f;
    } else {
      $ast->error("unsupported type " . $type . " for clj2perl object conversion");
    }
  }

  sub wrap_perlobj {
    my $v = shift;
    while(ref($v) eq "REF") {
      $v = ${$v};
    }
    return CljPerl::Atom->new("perlobject", $v);
  }

  sub perl2clj {
    my $v = shift; #$ast->value();
    if(! defined ref($v) or ref($v) eq ""){
      return CljPerl::Atom->new("string", $v);
    } elsif(ref($v) eq "SCALAR") {
      return CljPerl::Atom->new("string", ${$v});
    } elsif(ref($v) eq "HASH") {
      my %m = ();
      foreach my $k (keys %{$v}) {
        $m{$k} = &perl2clj($v->{$k});
      };
      return CljPerl::Atom->new("map", \%m);
    } elsif(ref($v) eq "ARRAY") {
      my @a = ();
      foreach my $i (@{$v}) {
        push @a, &perl2clj($i);
      };
      return CljPerl::Atom->new("vector", \@a);
    } elsif(ref($v) eq "CODE") {
      return CljPerl::Atom->new("perlfunction", $v);
    } else {
      return CljPerl::Atom->new("perlobject", $v);
      #$ast->error("expect a reference of scalar or hash or array");
    };
  }

  sub trace_vars {
    my $self = shift;
    print @{$self->scopes()} . "\n";
    foreach my $vn (keys %{$self->current_scope()}) {
      print "$vn\n" # . CljPerl::Printer::to_string(${$self->current_scope()}{$vn}->value()) . "\n";
    };
  } 

1;
