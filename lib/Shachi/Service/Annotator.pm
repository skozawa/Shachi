package Shachi::Service::Annotator;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Annotator;
use Shachi::Model::List;
use Shachi::Service::Resource;

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

sub find_by_id {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id;

    $db->shachi->table('annotator')->search({ id => $id })->single;
}

sub find_all {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    $db->shachi->table('annotator')->search({})->list;
}

sub embed_resources {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $annotators => { isa => 'Shachi::Model::List' },
         my $language => { isa => 'Shachi::Model::Language' },
         my $args => { isa => 'HashRef', default => {} };

    my $resources = $db->shachi->table('resource')->search({
        annotator_id => { -in => $annotators->map('id')->to_a },
    })->list;
    if ( $args->{with_resource_title} ) {
        Shachi::Service::Resource->embed_title(db => $db, resources => $resources, language => $language);
    }

    my $resources_by_annotator_id = $resources->hash_by('annotator_id');
    foreach my $annotator ( @$annotators ) {
        my @resources = $resources_by_annotator_id->get_all($annotator->id);
        $annotator->resources(Shachi::Model::List->new(list => [@resources]));
    }

    return $annotators;
}

sub embed_resource_count {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $annotators => { isa => 'Shachi::Model::List' };

    my $count_by_annotator_id = $db->shachi->table('resource')
        ->select(\'COUNT(*) as count, annotator_id')
        ->group_by('annotator_id')->list->hash_by('annotator_id');

    foreach my $annotator ( @$annotators ) {
        my $count = $count_by_annotator_id->{$annotator->id};
        $annotator->resource_count($count && $count->{count} || 0);
    }

    return $annotators;
}

1;
