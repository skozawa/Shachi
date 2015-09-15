package Shachi::Service::Annotator;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Annotator;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{name} or croak 'required name';
    $args->{mail} or croak 'required mail';
    $args->{organization} or croak 'required organization';

    my $annotator = $db->shachi->table('annotator')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'annotator', undef);

    Shachi::Model::Annotator->new(
        id => $last_insert_id,
        %$annotator,
    );
}

1;
