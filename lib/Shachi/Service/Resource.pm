package Shachi::Service::Resource;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use Shachi::Model::Resource;
use Shachi::Service::Resource::Metadata;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{annotator_id} or croak 'required annotator_id';
    $args->{status} ||= 'public';
    $args->{edit_status} ||= EDIT_STATUS_NEW;
    $args->{shachi_id} = ''; # dummy
    my $resource_subject = delete $args->{resource_subject};

    my $resource = $db->shachi->table('resource')->insert($args);
    my $last_insert_id = $db->shachi->dbh->last_insert_id(undef, undef, 'resource', undef);

    my $shachi_id = $class->shachi_id(
        resource_id => $last_insert_id,
        resource_subject => $resource_subject
    );
    $db->shachi->table('resource')
        ->search({ id => $last_insert_id })->update({ shachi_id => $shachi_id });

    Shachi::Model::Resource->new(
        %$resource,
        id => $last_insert_id,
        shachi_id => $shachi_id,
    );
}

sub shachi_id {
    args my $class => 'ClassName',
         my $resource_id,
         my $resource_subject => { optional => 1 };

    my $prefix = do {
        if ( !defined $resource_subject ) {
            'N';
        } elsif ( $resource_subject eq 'corpus' ) {
            'C';
        } elsif ( $resource_subject eq 'dictionary' ) {
            'D';
        } elsif ( $resource_subject eq 'glossary' ) {
            'G';
        } elsif ( $resource_subject eq 'thesaurus' ) {
            'T';
        } else {
            'O';
        }
    };

    return sprintf '%s-%06d', $prefix, $resource_id;
}

sub search_all {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    return $db->shachi->table('resource')->search({
        status => 'public',
    })->order_by('id asc')->list;
}

sub embed_title {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $resources => { isa => 'Shachi::Model::List' };

    my $resource_titles = Shachi::Service::Resource::Metadata->find_resource_titles(
        db => $db, resource_ids => $resources->map('id')->to_a,
    );
    my $title_by_resource_id = $resource_titles->hash_by('resource_id');

    foreach my $resource ( @$resources ) {
        my $title_metadata = $title_by_resource_id->{$resource->id} or next;
        $resource->title($title_metadata->content);
    }

    return $resources;
}

1;
