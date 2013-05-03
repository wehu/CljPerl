package CljPerl::SocketServer;

use strict;
use warnings;


our $VERSION = '0.06';

use AnyEvent::Socket;
use AnyEvent::Handle;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

sub socket_server {
    my $host = shift;
    my $port = shift;
    my $sscb = shift;

    return AnyEvent::Socket::tcp_server $host, $port, sub {
        my ($clsock, $host, $port) = @_;
    
        my $hs    = Protocol::WebSocket::Handshake::Server->new;
        my $frame = Protocol::WebSocket::Frame->new;
    
        my $hdl = AnyEvent::Handle->new(fh => $clsock);
        $hdl->on_error(
            sub {
              my ($hdl, $fatal, $message) = @_;
              print "$message\n";
              $hdl->destroy;
            }
        );
        $hdl->on_eof(
            sub {}
        );
        $hdl->{__on_read__} =
        sub {
            my $cb = shift;
            sub {
                my $hdl = shift;
                my $chunk = $hdl->{rbuf};
                $hdl->{rbuf} = undef;
                if (!$hs->is_done) {
                    $hs->parse($chunk);
                    if ($hs->is_done) {
                        $hdl->push_write($hs->to_string);
                        return;
                    }
                }
                $frame->append($chunk);
                while (my $message = $frame->next) {
                    &{$cb}($message);
                #    $hdl->push_write($frame->new($nmessage)->to_bytes);
                };
            }
        };
        $hdl->{__send__} =
        sub {
           my $msg = shift;
           $hdl->push_write($frame->new($msg)->to_bytes);
           #$hdl->push_write($hs->to_string);
        };
        &{$sscb}($hdl);
    };
};

sub socket_send {
  my $socket = shift;
  my $msg = shift;
  if(defined $socket){
    $socket->{__send__}->($msg);
  };
};

sub socket_on_read {
  my $socket = shift;
  my $cb = shift;
  if(defined $socket) {
    $socket->on_read($socket->{__on_read__}->($cb));
  };
};

sub socket_destroy {
  my $socket = shift;
  $socket->destroy;
};

1;

