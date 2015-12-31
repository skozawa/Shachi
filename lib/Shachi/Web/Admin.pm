package Shachi::Web::Admin;
use strict;
use warnings;
use List::Util qw/sum/;
use Shachi::Service::Annotator;

sub default {
    my ($class, $c) = @_;

    my $annotators = Shachi::Service::Annotator->find_all(db => $c->db);
    Shachi::Service::Annotator->embed_resource_count(
        db => $c->db, annotators => $annotators,
    );

    my $annotator_id = $c->req->param('annotator_id');
    if ( defined $annotator_id ) {
        Shachi::Service::Annotator->embed_resources(
            db => $c->db, language => $c->admin_lang,
            annotators => $annotator_id ? $annotators->grep(sub { $_->id == $annotator_id }) : $annotators,
            args => { with_resource_title => 1 },
        );
    }

    return $c->html('admin/index.html', {
        total_count => sum($annotators->map(sub { $_->resource_count })->deref),
        annotators => $annotators,
    });
}

1;
