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
    rw  => [qw/current_values total_count search_count/],
    ro_lazy => [qw/all_value_ids search_query offset limit/],
);

sub _build_all_value_ids {
    my $self = shift;
    [ map { @{$self->valid_value_ids($_)} } @{FACET_METADATA_NAMES()} ];
}

sub _build_offset {
    my $self = shift;
    $self->params->{offset} || 0;
}

sub _build_limit {
    my $self = shift;
    $self->params->{limit} || 10;
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
    [ grep { any { $_ == 0 } @{$self->value_ids($_)} } @{FACET_METADATA_NAMES()} ];
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

## paging
sub current_page_num {
    my $self = shift;
    int($self->offset / $self->limit) + 1;
}

sub pages {
    my ($self, $num) = @_;
    [ grep { $self->has_page($_) } ($self->current_page_num - $num .. $self->current_page_num + $num) ];
}

sub max_search_page_num {
    my $self = shift;
    return 0 unless $self->search_count;
    int($self->search_count / $self->limit) + 1;
}

sub has_prev {
    my $self = shift;
    $self->has_page($self->current_page_num - 1);
}

sub has_next {
    my $self = shift;
    $self->has_page($self->current_page_num + 1);
}

sub has_page {
    my ($self, $page) = @_;
    return 0 if $page < 1;
    return 0 unless $self->max_search_page_num;
    return 0 if $page > $self->max_search_page_num;
    return 1;
}

sub page_offset {
    my ($self, $page) = @_;
    ($page - 1) * $self->limit;
}

sub current_search_last_index {
    my $self = shift;
    $self->search_count > $self->offset + $self->limit ?
        $self->offset + $self->limit : $self->search_count;
}

1;
