package Shachi::Web::Resource;
use strict;
use warnings;
use Shachi::Service::Resource;

sub list {
    my ($class, $c) = @_;
    my $resources = Shachi::Service::Resource->search_all(db => $c->db);
    Shachi::Service::Resource->embed_title(db => $c->db, resources => $resources);
    return $c->html('list.html', { resources => $resources });
}

1;
