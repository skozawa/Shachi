package Shachi::Service::FacetSearch;
use strict;
use warnings;
use Smart::Args;
use Shachi::Model::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;

sub facet_metadata_list {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    my $facet_names = FACET_METADATA_NAMES;
    my $facet_metadata_list = Shachi::Service::Metadata->find_by_names(
        db => $db, names => $facet_names,
        args => { order_by_names => 1 },
    );

    return $facet_metadata_list;
}


1;
