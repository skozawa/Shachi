package Shachi::Web::Admin::Resource;
use strict;
use warnings;
use JSON::Types;
use List::MoreUtils qw/firstval/;
use Shachi::Model::Metadata;
use Shachi::Model::Language;
use Shachi::Service::Annotator;
use Shachi::Service::Language;
use Shachi::Service::Resource;
use Shachi::Service::Resource::Metadata;
use Shachi::Service::Metadata;
use Shachi::Service::Metadata::Value;
use Shachi::Util qw/format_content/;

sub find_by_id {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my ($resource, $metadata_list) = Shachi::Service::Resource->find_resource_detail(
        db => $c->db, id => $resource_id, language => $c->admin_lang,
        args => { with_value => 1 },
    );
    return $c->throw_not_found unless $resource;

    my $annotators = Shachi::Service::Annotator->find_all(db => $c->db);
    Shachi::Service::Metadata->embed_metadata_values(
        db => $c->db, metadata_list => $metadata_list
    );
    return $c->html('admin/resource.html', {
        resource => $resource,
        metadata_list => $metadata_list,
        annotators => $annotators,
    });
}

sub create_get {
    my ($class, $c) = @_;

    my $annotators = Shachi::Service::Annotator->find_all(db => $c->db);
    my $metadata_list = Shachi::Service::Metadata->find_shown_metadata(db => $c->db);
    Shachi::Service::Metadata->embed_metadata_values(
        db => $c->db, metadata_list => $metadata_list
    );

    return $c->html('admin/resource/create.html', {
        annotators    => $annotators,
        metadata_list => $metadata_list,
    });
}

sub create_post {
    my ($class, $c) = @_;
    my $contents = $c->req->json;
    my $resource_subject = _resource_subject_from_contents($c->db, $contents);
    my $resource = Shachi::Service::Resource->create(db => $c->db, args => {
        annotator_id => $contents->{annotator_id},
        status       => $contents->{status},
        resource_subject => $resource_subject,
    });

    Shachi::Service::Resource::Metadata->create_multi_from_json(
        db => $c->db, resource_id => $resource->id, json => $contents,
    );

    $c->json({ resource_id => $resource->id });
}

sub _resource_subject_from_contents {
    my ($db, $contents) = @_;
    my $resource_subject = firstval { $_->{value_id} } @{$contents->{subject_resourceSubject} || []};
    return unless $resource_subject;
    my $value = Shachi::Service::Metadata::Value->find_by_id(db => $db, id => $resource_subject->{value_id});
    $value->value;
}

sub search {
    my ($class, $c) = @_;
    my $query = $c->req->param('query') or $c->throw_bad_request;

    my $resources = Shachi::Service::Resource->search_titles(
        db => $c->db, query => $query
    );

    $c->json({
        resources => $resources->map(sub {
            +{ id => $_->id, title => $_->title, shachi_id => $_->shachi_id }
        })->to_a,
    });
}

sub delete {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->delete_by_id(db => $c->db, id => $resource->id);

    if ( $c->req->method eq 'DELETE' || ($c->req->header('Content-Type') || '') eq 'application/json' ) {
        $c->json({ success => JSON::Types::bool(1) });
    } else {
        $c->redirect('/admin/?annotator_id=' . $resource->annotator_id);
    }
}

sub update_annotator {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $annotator_id = $c->req->param('annotator_id') or return $c->throw_bad_request;

    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    my $annotator = Shachi::Service::Annotator->find_by_id(db => $c->db, id => $annotator_id);
    return $c->throw_bad_request unless $annotator;

    Shachi::Service::Resource->update_annotator(
        db => $c->db, id => $resource_id, annotator_id => $annotator_id,
    );

    $c->json({ annotator => { id => $annotator->id, name => $annotator->name } });
}

sub update_status {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $status = $c->req->param('status') or return $c->throw_bad_request;

    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->update_status(
        db => $c->db, id => $resource_id, status => $status,
    );

    $c->json({ status => $status });
}

sub update_edit_status {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $edit_status = $c->req->param('edit_status') or return $c->throw_bad_request;

    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    Shachi::Service::Resource->update_edit_status(
        db => $c->db, id => $resource_id, edit_status => $edit_status,
    );

    $c->json({ edit_status => $edit_status });
}

sub update_metadata {
    my ($class, $c) = @_;
    my $resource_id = $c->route->{resource_id};
    my $resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
    return $c->throw_not_found unless $resource;

    my $contents = $c->req->json;
    my $language = Shachi::Service::Language->find_by_code(
        db => $c->db, code => $contents->{metadata_language} || ENGLISH_CODE,
    );

    my $require_update_relation = $contents->{METADATA_SUBJECT_RESOURCE_SUBJECT()} || $contents->{METADATA_TITLE()};
    # relationの更新に使うのでタイトルを更新する前に現在のタイトル埋める
    Shachi::Service::Resource->embed_title(
        db => $c->db, resources => $resource->as_list, language => $language,
    ) if $require_update_relation;

    my $metadata_list = Shachi::Service::Metadata->find_by_names(
        db => $c->db, names => [ keys %$contents ],
    );
    Shachi::Service::Resource::Metadata->update_multi_from_json(
        db => $c->db, resource_id => $resource->id, json => $contents,
        metadata_list => $metadata_list,
    );
    Shachi::Service::Resource->update_modified(
        db => $c->db, id => $resource->id,
    );

    # resource_subject を更新する場合はshachi_idも更新する
    if ( $contents->{METADATA_SUBJECT_RESOURCE_SUBJECT()} ) {
        my $resource_subject = _resource_subject_from_contents($c->db, $contents);
        Shachi::Service::Resource->update_shachi_id(
            db => $c->db, id => $resource->id, resource_subject => $resource_subject,
        );
    }

    my $resource_metadata_by_metadata_name = Shachi::Service::Resource::Metadata->find_resource_metadata(
        db => $c->db, resource => $resource, metadata_list => $metadata_list,
        language => $language, args => { with_value => 1 },
    )->hash_by('metadata_name');

    # title, shachi_id が変更される場合はrelationの値も更新する
    if ( $require_update_relation ) {
        my $updated_resource = Shachi::Service::Resource->find_by_id(db => $c->db, id => $resource_id);
        Shachi::Service::Resource->embed_title(
            db => $c->db, resources => $updated_resource->as_list, language => $language,
        );
        Shachi::Service::Resource::Metadata->update_resource_relation(
            db => $c->db, old => $resource->relation_value, new => $updated_resource->relation_value,
        );
    }

    my $res = {};
    foreach my $metadata ( @$metadata_list ) {
        my @resource_metadata_list = $resource_metadata_by_metadata_name->get_all($metadata->name);
        $res->{$metadata->name} = [ map {
            +{
                $_->value ? (
                    value_id => $_->value->id,
                    value    => $_->value->value,
                ) : (),
                content => $_->content,
                description => $_->description,
                formatted_content => format_content($_->content),
            }
        } @resource_metadata_list ];
    }

    $c->json({ resource_id => $resource->id, %$res })
}

1;
