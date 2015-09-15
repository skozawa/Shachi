package Shachi::Model::Metadata;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

use constant VALUE_TYPE_LANGUAGE => 'language';

our @EXPORT = qw/
    VALUE_TYPE_LANGUAGE
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id name label order_num shown multi_value input_type value_type color/],
);

1;
