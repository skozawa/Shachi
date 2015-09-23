package Shachi::FacetSearchQuery;
use strict;
use warnings;
use List::MoreUtils qw/any uniq/;
use Search::Query;
use Search::Query::Dialect::SQL;
use Shachi::Model::Metadata;
use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/params/],
    rw  => [qw/current_values/],
    ro_lazy => [qw/all_value_ids search_query/],
);

sub _build_all_value_ids {
    my $self = shift;
    [ map { @{$self->valid_value_ids($_)} } @{FACET_METADATA_NAMES()} ];
}

sub _build_search_query {
    my $self = shift;
    my $parser = Search::Query->parser(
        query_class => 'Search::Query::Dialect::SQL',
        fields      => ['content'],
    );
    return $parser->parse($self->keyword);
}

sub search_query_sql {
    my $self = shift;
    my $keyword_sql = $self->search_query->stringify;
    $keyword_sql =~ s!content='!content REGEXP '!g;
    $keyword_sql =~ s!;!!g; # for sql injection
    return $keyword_sql;
}

# includes 0 (= no information)
sub value_ids {
    my ($self, $name) = @_;
    return [] unless $name;
    $self->{"_$name-value"} ||= [ uniq grep { length $_ } $self->params->get_all($name) ];
}

# not includes 0
sub valid_value_ids {
    my ($self, $name) = @_;
    return [] unless $name;
    $self->{"_$name-valid-value"} ||= [ grep { $_ } @{$self->value_ids($name)} ];
}

sub keyword {
    my $self = shift;
    $self->params->{keyword};
}

sub has_keyword {
    my $self = shift;
    length $self->keyword ? 1 : 0;
}

sub has_any_query {
    my $self = shift;
    return 1 if $self->has_keyword;
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
