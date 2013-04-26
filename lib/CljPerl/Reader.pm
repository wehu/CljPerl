package CljPerl::Reader;

  use strict;
  use warnings;
  use autodie;
  use CljPerl::Seq;
  use CljPerl::Atom;
  use CljPerl::Logger;

  our $VERSION = '0.01';

  sub new {
    my $class = shift;
    my $self = {class  => $class,
	        ast    => {},
                nest   => 0,
	        filehandler   => undef,
	        filename => "unknown",
	        line   => 1,
	        col    => 1};
    bless $self;
    return $self;
  }

  sub class {
    my $self = shift;
    return $self->{class};
  }

  sub filehandler {
    my $self = shift;
    my $fh = shift;
    if(defined $fh) {
      $self->{filehandler} = $fh;
    } else {
      return $self->{filehandler};
    }
  }

  sub filename {
    my $self = shift;
    my $fn = shift;
    if(defined $fn) {
      $self->{filename} = $fn;
    } else {
      return $self->{filename};
    }
  }

  sub line {
    my $self = shift;
    my $line = shift;
    if(defined $line) {
      $self->{line} = $line;
    } else {
      return $self->{line};
    };
  }

  sub col {
    my $self = shift;
    my $col = shift;
    if(defined $col) {
      $self->{col} = $col;
    } else {
      return $self->{col};
    };
  }

  sub ast {
    my $self = shift;
    return $self->{ast};
  }

  sub peekc {
    my $self = shift;
    my $fh = $self->filehandler();
    die "file handler is un-defined" if(!defined $fh);
    my $c = undef;
    if(!eof($fh)) {
      $c = getc($fh);
      seek($fh, -1, 1);
    }
    return $c;
  }

  sub readc {
    my $self = shift;
    my $fh = $self->filehandler();
    my $c = $self->peekc();
    if(defined $c) {
      if($c eq "\n"){
        $self->line(1 + $self->line());
        $self->col(1);
      } else {
        $self->col(1 + $self->col());
      };
      seek($fh, 1, 1);
    };
    return $c;
  }

  sub consume {
    my $self = shift;
    my $offset = shift;
    for(my $i=0; $i<$offset; $i++){
      $self->readc();
    }
  }

  sub skip_blanks {
    my $self = shift;
    my $c = undef;
    do {
      $c = $self->peekc();
      if(defined $c){
        if($c eq ";"){
          $self->consume(1);
          $self->comment();
        } elsif($c =~ /\s/) {
          $self->consume(1);
        } else {
          $c = undef;
        }
      } else {
        $c = undef;
      }
    } until ! defined $c;
  }

  sub parse {
    my $self = shift;
    my $file_or_str = shift;
    my $mode = shift;
    $mode = "string" if !defined $mode;
    my $fh = undef;
    if($mode eq "string"){
      open $fh, "<", \$file_or_str or die "cannot read string $file_or_str";
    } else {
      open $fh, "<:encoding(utf8)", $file_or_str or die "cannot open file $file_or_str";
    };
    $self->filehandler($fh);
    $self->filename($file_or_str);
    $self->line(1);
    $self->col(1);
    my $ast = CljPerl::Seq->new();
    do {
      $self->skip_blanks();
      my $r = $self->lex();
      $ast->append($r) if defined $r;
    } until eof($fh);
    $self->{ast} = $ast;
    close $fh if $mode ne "string";
  }

  sub read_file {
    my $self = shift;
    my $file = shift;
    $self->parse($file, "file");
  }

  sub read_string {
    my $self = shift;
    my $str = shift;
    $self->parse($str);
  }

  sub show {
    my $self = shift;
    my $indent = shift;
    $indent = "" if !defined $indent;
    $self->{ast}->show($indent);
  }

  sub lex {
    my $self = shift;
    my $c = $self->peekc();
    if(defined $c) {
      if($c eq '(') {
	return $self->seq("list", "(", ")");
      } elsif($c eq '"') {
        return $self->string();
      } elsif($c =~ /\d/) {
        return $self->number();
      } elsif($c eq '[') {
	return $self->seq("vector", "[", "]");
      } elsif($c eq '{') {
        return $self->seq("map", "{", "}");
      #} elsif($c eq '#') {
      #  return $self->dispatch();
      } elsif($c eq '^') {
        $self->consume(1);
        $self->error("meta should be a map") if $self->peekc() ne "{";
        my $md = $self->lex();
	$md->type("meta");
	return $md;
      } elsif($c eq ':') {
        $self->consume(1);
        my $k = $self->symbol();
        $k->type("keyword");
        return $k;
      } elsif($c eq "'") {
	$self->consume(1);
        my $q = $self->lex();
	$q->type("quotation");
	return $q;
      } elsif($c eq "`") {
	$self->consume(1);
        my $sq = $self->seq();
	$sq->type("syntaxquotation");
	return $sq;
      } elsif($c eq "~") {
	$self->consume(1);
        my $dq = $self->symbol();
	$dq->type("dequotation");
	return $dq;
      #} elsif($c eq "@") {
      #  $self->consume(1);
      #  my $dr = $self->symbol();
      #$dr->type("deref");
      #return $dr;
      } elsif($c eq ";") {
        $self->consume(1);
        $self->comment();
        return undef;
      } elsif(($c eq ')' or $c eq ']' or $c eq '}')
              and $self->{nest} == 0) {
        $self->error("unexpected " . $c);
      } else {
	return $self->symbol();
      };
    };
    return undef;
  }

  sub comment {
    my $self = shift;
    my $c = undef;
    do {
      $c = $self->readc();
      if(defined $c and $c eq "\n"){
        $c = undef;
      }
    } until ! defined $c;
    $self->skip_blanks();

    return undef;
  }

  sub string {
    my $self = shift;
    my $c = undef;
    my $s = CljPerl::Atom->new("string");
    $s->{pos} = {filename=>$self->filename(),
                 line=>$self->line(),
                 col=>$self->col()};
    $self->consume(1);
    do {
      $c = $self->peekc();
      if(defined $c){
        if($c eq "\\") {
          $self->consume(1);
          my $nc = $self->peekc();
          $self->error("unexpected eof") if !defined $nc;
          $self->consume(1);
          my $rc = $nc;
          if($nc eq "a") {
            $rc = "\a";
          } elsif($nc eq "b") {
            $rc = "\b";
          } elsif($nc eq "e") {
            $rc = "\e";
          } elsif($nc eq "f") {
            $rc = "\f";
          } elsif($nc eq "n") {
            $rc = "\n";
          } elsif($nc eq "r") {
            $rc = "\r";
          } elsif($nc eq "t") {
            $rc = "\t";
          };
          $s->{value} .= $rc;
	} elsif($c ne '"') {
          $s->{value} .= $c;
          $self->consume(1);
        } else {
          $c = undef;
	};
      };
    } until ! defined $c;
    $c = $self->peekc();
    if(defined $c and $c eq '"'){
      $self->consume(1);
    } else {
      $self->error("expect \"");
    }
    $self->skip_blanks();
    return $s;
  }

  sub number {
    my $self = shift;
    my $c = undef;
    my $n = CljPerl::Atom->new("number");
    $n->{pos} = {filename=>$self->filename(),
                 line=>$self->line(),
                 col=>$self->col()};
    do {
      $c = $self->peekc();
      if(defined $c
            and $c =~ /\S/
            and $c ne ";"
            and $c ne '(' and $c ne ')'
	    and $c ne '[' and $c ne ']'
	    and $c ne '{' and $c ne '}') {
        if($c =~ /[\+\-\d\.xXabcdefABCDEF\/\_]/) {
          $self->consume(1);
          $n->{value} .= $c;
        } else {
          $self->error("unexpect letter " . $c . " for number");
	};
      } else {
        $c = undef;
      };
    } until ! defined $c;
    local $SIG{__WARN__} = sub {
      $n->error("invild number literal " . $n->{value});
    };
    $n->{value} = 0 + $n->{value};
    delete $SIG{__WARN__};
    $self->skip_blanks();
    return $n;
  }

  sub symbol {
    my $self = shift;
    my $c = undef;
    my $sym = CljPerl::Atom->new("symbol");
    $self->skip_blanks();
    $sym->{pos} = {filename=>$self->filename(),
                   line=>$self->line(),
                   col=>$self->col()};
    do {
      $c = $self->peekc();
      if(defined $c){
        if($c =~ /\S/
            and $c ne ';'
            and $c ne '(' and $c ne ')'
	    and $c ne '[' and $c ne ']'
	    and $c ne '{' and $c ne '}') {
          $self->error("unexpected letter " . $c . " for symbol")
            if $c =~ /[^0-9a-zA-Z_!&\?\*\/\.\+\|=%\$<>#@\:\-]/;
          $sym->{value} .= $c;
	  $self->consume(1);
	} else {
	  $c = undef;
	};
      };
    } until ! defined $c;
    $self->skip_blanks();
    if($sym->{value} eq "") {
      return undef;
    } else {
      return $sym;
    }
  }

  sub seq {
    my $self = shift;
    my $type = shift;
    my $begin = shift;
    my $end  = shift;
    $type = "list" if !defined $type;
    $begin = "(" if !defined $begin;
    $end = ")" if !defined $end;
    my $e = undef;
    my $c = $self->peekc();
    if(defined $c and $c eq $begin){
      $self->consume(1);
    } else {
      $self->error("expect " . $begin);
    };
    my $seq = CljPerl::Seq->new($type);
    $seq->{pos} = {filename=>$self->filename(),
                   line=>$self->line(),
                   col=>$self->col()};
    $self->{nest} += 1;
    do {
      $e = $self->lex();
      $self->skip_blanks();
      $seq->append($e) if defined $e;
    } until ! defined $e;
    $c = $self->peekc();
    if(defined $c and $c eq $end){
      $self->consume(1);
      $self->{nest} -= 1;  
    } else {
      $self->error("expect " . $end);
    };
    $self->skip_blanks();
    return $seq;
  }

  sub error {
    my $self = shift;
    my $msg = shift;
    $msg .= " @[file: " . $self->filename();
    $msg .= "; line: " . $self->line();
    $msg .= "; col: " . $self->col() . "]";
    CljPerl::Logger::error($msg);
  }
1;
