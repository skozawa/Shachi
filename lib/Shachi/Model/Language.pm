package Shachi::Model::Language;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

use constant {
    ENGLISH_CODE => 'eng',
};

our @EXPORT = qw/
    ENGLISH_CODE
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id code name area value_id/],
);

1;
