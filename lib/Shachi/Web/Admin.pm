package Shachi::Web::Admin;
use strict;
use warnings;
use Shachi::Service::Annotator;

sub default {
    my ($class, $c) = @_;

    my $annotators = Shachi::Service::Annotator->find_all(db => $c->db);
    Shachi::Service::Annotator->embed_resource_count(
        db => $c->db, annotators => $annotators,
    );

    my $annotator = do {
        if ( my $annotator_id = $c->req->param('annotator_id') ) {
            my $annotator = Shachi::Service::Annotator->find_by_id(
                db => $c->db, id => $annotator_id,
            );
            if ( $annotator ) {
                Shachi::Service::Annotator->embed_resources(
                    db => $c->db, annotators => $annotator->as_list, language => $c->admin_lang,
                    args => { with_resource_title => 1 },
                );
                $annotator;
            }
        }
    };

    return $c->html('admin/index.html', {
        annotator  => $annotator,
        annotators => $annotators,
    });
}

1;
