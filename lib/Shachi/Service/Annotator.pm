package Shachi::Service::Annotator;
use strict;
use warnings;
use Shachi::Model::Annotator;

sub create {
    my ($class, $db, $args) = @_;

    my $annotator = $db->shachi->table('annotator')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'annotator', undef);

    Shachi::Model::Annotator->new(
        id => $last_insert_id,
        %$annotator,
    );
}

1;
