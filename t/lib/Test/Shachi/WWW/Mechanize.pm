package Test::Shachi::WWW::Mechanize;
use strict;
use warnings;
use parent qw/Test::WWW::Mechanize::PSGI/;
use Test::More ();
use Shachi::Web;

BEGIN {
    $ENV{PLACK_ENV} = 'test';
}

sub new {
    my ($class, %args) = @_;

    my $self;
    my $app = sub {
        my $env = shift;
        $self->{env} = $env;
        my $res = Shachi::Web->run($env);
        $res;
    };

    $self = $class->SUPER::new(
        onerror => \&Test::More::diag,
        onwarn  => \&Test::More::diag,
        app     => $app,
        %args,
    );

    return $self;
}

1;
