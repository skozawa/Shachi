package Shachi::Web::Admin::Language;
use strict;
use warnings;
use JSON::Types;
use Shachi::Service::Language;

sub search {
    my ($class, $c) = @_;
    my $query = $c->req->param('query') or $c->throw_bad_request;

    my $languages = Shachi::Service::Language->search_by_query(db => $c->db, query => $query);

    $c->json({
        languages => $languages->map(sub { +{ code => $_->code, name => $_->name } })->to_a
    });
}

1;
