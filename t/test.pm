package t::test;

use strict;
use warnings;

BEGIN {
    $ENV{PLACK_ENV} = 'test';
    $ENV{SHACHI_ENV} = 'test';
}

use lib glob '{.,t,modules/*}/lib';

sub import {
    my $class = shift;
    my ($pkg, $file) = caller;

    strict->import;
    pwarnings->import;
    utf8->import;

    my $code = qq[
        package $pkg;

        use parent qw/Test::Class/;
        use t::test::factory;
        use Test::More;
        use Test::Time;
        use Test::Deep;
        use Test::Fatal qw/dies_ok lives_ok/;
        use Test::Mock::Guard;
        use Test::WWW::Stub;
        use Data::Dumper;

        END {
            $pkg->runtests;
        }
    ];

    eval $code;
    die $@ if $@;
}

1;

