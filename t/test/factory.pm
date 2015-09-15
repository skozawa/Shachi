package t::test::factory;

use strict;
use warnings;

use lib glob '{.,t,modules/*}/lib';
use Exporter::Lite;

our @EXPORT = qw/
    create_mech
/;

sub create_mech {
    my (%args) = @_;

    require Test::Shachi::WWW::Mechanize;
    return Test::Shachi::WWW::Mechanize->new(%args);
}

1;
