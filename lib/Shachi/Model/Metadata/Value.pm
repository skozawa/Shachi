package Shachi::Model::Metadata::Value;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

use constant {
    LANGUAGE_AREA_ASIA  => 'Asia',
    LANGUAGE_AREA_JAPAN => 'Japan',
};

our @EXPORT = qw/
    LANGUAGE_AREA_ASIA LANGUAGE_AREA_JAPAN
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id value_type value/],
    rw  => [qw/resource_count/],
);

1;
