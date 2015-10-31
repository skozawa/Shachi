package Shachi::Service::Resource;
use strict;
use warnings;
use Carp qw/croak/;
use Smart::Args;
use List::MoreUtils qw/any/;
use Shachi::Model::List;
use Shachi::Model::Resource;
use Shachi::Service::Annotator;
use Shachi::Service::Metadata;
use Shachi::Service::Resource::Metadata;

sub create {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef' };

    $args->{annotator_id} or croak 'required annotator_id';
    $args->{status} ||= 'public';
    $args->{edit_status} ||= EDIT_STATUS_NEW;
    $args->{shachi_id} = ''; # dummy
    $args->{created} ||= $db->shachi->now;
    $args->{modified} ||= $db->shachi->now;
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

sub find_by_id {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id;

    $db->shachi->table('resource')->search({ id => $id })->single;
}

sub find_by_ids {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $ids   => { isa => 'ArrayRef' };

    $db->shachi->table('resource')->search({ id => { -in => $ids } })->list;
}

sub find_resource_detail {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id,
         my $args  => { isa => 'HashRef', default => {} };

    my $resource = $class->find_by_id(db => $db, id => $id) or return;
    my $metadata_list = delete $args->{metadata_list};
    $metadata_list ||= Shachi::Service::Metadata->find_shown_metadata(db => $db);

    my $resource_metadata_list = Shachi::Service::Resource::Metadata->find_resource_metadata(
        db => $db, resource => $resource, metadata_list => $metadata_list,
        args => { with_value => 1 },
    );

    $resource->metadata_list($resource_metadata_list);
    if (my $title_metadata = $metadata_list->grep(sub { $_->name eq 'title' })->first) {
        my $titles = $resource->metadata($title_metadata);
        $resource->title($titles->[0]->content) if @$titles;
    }

    my $annotator = Shachi::Service::Annotator->find_by_id(db => $db, id => $resource->annotator_id);
    $resource->annotator($annotator);

    return ($resource, $metadata_list);
}

sub search_all {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    return $db->shachi->table('resource')->search({
        status => 'public',
    })->order_by('id asc')->list;
}

sub search_titles {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $query => { isa => 'Str' };

    my $title_metadata = Shachi::Service::Metadata->find_by_name(db => $db, name => 'title');
    return Shachi::Model::List->new( list => [] ) unless $title_metadata;
    my $resource_metadata_list = $db->shachi->table('resource_metadata')->search({
        metadata_id => $title_metadata->id,
        content => { regexp => $query },
    })->list;

    my $title_by_resource_id = $resource_metadata_list->hash_by('resource_id');
    my $resources = $class->find_by_ids(
        db => $db, ids => $resource_metadata_list->map('resource_id')->to_a,
    );

    foreach my $resource ( @$resources ) {
        my $title_metadata = $title_by_resource_id->{$resource->id} or next;
        $resource->title($title_metadata->content);
    }

    return $resources;
}

sub count_not_private {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' };

    return $db->shachi->table('resource')->search({
        status => { '!=' => 'private' }
    })->count;
}

sub embed_title {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $resources => { isa => 'Shachi::Model::List' };

    my $resource_titles = Shachi::Service::Resource::Metadata->find_resource_metadata_by_name(
        db => $db, name => 'title', resource_ids => $resources->map('id')->to_a,
    );
    my $title_by_resource_id = $resource_titles->hash_by('resource_id');

    foreach my $resource ( @$resources ) {
        my $title_metadata = $title_by_resource_id->{$resource->id} or next;
        $resource->title($title_metadata->content);
    }

    return $resources;
}

sub update_shachi_id {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id,
         my $resource_subject => { optional => 1 };

    my $shachi_id = $class->shachi_id(
        resource_id => $id,
        resource_subject => $resource_subject
    );
    $db->shachi->table('resource')->search({
        id => $id,
    })->update({ shachi_id => $shachi_id });
}

sub update_annotator {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id,
         my $annotator_id;

    $db->shachi->table('resource')->search({
        id => $id,
    })->update({ annotator_id => $annotator_id });
}

sub update_status {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id,
         my $status;

    croak 'invalid status'
        unless any { $status eq $_ } @{STATUSES()};

    $status = _status($db, $id, $status);

    $db->shachi->table('resource')->search({
        id => $id,
    })->update({ status => $status });
}

sub _status {
    my ($db, $id, $status) = @_;
    return $status if $status eq STATUS_PRIVATE;
    my $identifiers = Shachi::Service::Resource::Metadata->find_resource_metadata_by_name(
        db => $db, name => 'identifier', resource_ids => [ $id ],
    );
    return STATUS_PUBLIC unless $identifiers->size;
    return STATUS_LIMITED_BY_LDC  if $identifiers->first->content =~ /^LDC/;
    return STATUS_LIMITED_BY_ELRA if $identifiers->first->content =~ /^ELRA/;
    return STATUS_PUBLIC;
}

sub update_edit_status {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id,
         my $edit_status;

    croak 'invalid edit_status'
        unless any { $edit_status eq $_ } @{EDIT_STATUSES()};

    $db->shachi->table('resource')->search({
        id => $id,
    })->update({ edit_status => $edit_status });
}

sub update_modified {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id;

    $db->shachi->table('resource')->search({
        id => $id,
    })->update({ modified => $db->shachi->now });
}

sub delete_by_id {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $id;

    $db->shachi->table('resource')->search({
        id => $id,
    })->delete;
    $db->shachi->table('resource_metadata')->search({
        resource_id => $id,
    })->delete;
}

1;
