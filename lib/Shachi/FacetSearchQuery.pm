package Shachi::FacetSearchQuery;
use strict;
use warnings;
use List::MoreUtils qw/any uniq/;
use Shachi::Model::Metadata;
use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/params/],
    rw  => [qw/current_values/],
    ro_lazy => [qw/all_value_ids/],
);

sub _build_all_value_ids {
    my $self = shift;
    [ map { @{$self->valid_value_ids($_)} } @{FACET_METADATA_NAMES()} ];
}

# includes 0 (= no information)
sub value_ids {
    my ($self, $name) = @_;
    $self->{"_$name-value"} ||= [ uniq grep { length $_ } $self->params->get_all($name) ];
}

# not includes 0
sub valid_value_ids {
    my ($self, $name) = @_;
    $self->{"_$name-valid-value"} ||= [ grep { $_ } @{$self->value_ids($name)} ];
}

sub has_any_query {
    my $self = shift;
    any { @{$self->value_ids($_)} } @{FACET_METADATA_NAMES()};
}

sub no_info_metadata_names {
    my $self = shift;
    [ grep { length $self->params->{$_} && $self->params->{$_} == 0 } @{FACET_METADATA_NAMES()} ];
}

sub value_by_id {
    my ($self, $id) = @_;
    return unless $self->current_values;
    $self->{_value_by_id} ||= $self->current_values->hash_by('id');
    $self->{_value_by_id}->{$id};
}

sub has_value {
    my ($self, $name, $value_id) = @_;
    any { $_ == $value_id } $self->value_ids($name);
}

1;
