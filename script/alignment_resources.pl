use strict;
use warnings;
use utf8;
use Data::Dumper;
use List::Util qw/sum/;
use Shachi::Database;
use Shachi::Model::List;
use Shachi::Model::Metadata;
use Shachi::Service::Resource;

$ENV{PLACK_ENV} ||= 'development';

my $db = Shachi::Database->new;

my $english = Shachi::Service::Language->find_by_code(db => $db, code => 'eng');
die 'Not Found english' unless $english;
my $japanese = Shachi::Service::Language->find_by_code(db => $db, code => 'jpn');
die 'Not Found japanese' unless $japanese;

alignment_resources($ARGV[0]);

sub alignment_resources {
    my ($file) = @_;

    open(IN, $file);
    while (<IN>) {
        chomp;
        my ($id_jpn, $id_eng, $title_jpn, $title_eng) = split /\t/;

        migrate_resource($id_jpn, $id_eng);
    }
    close(IN);
}

sub migrate_resource {
    my ($id_jpn, $id_eng) = @_;
    return unless $id_jpn;
    warn $id_jpn;
    my $resource_jpn = Shachi::Service::Resource->find_by_id(db => $db, id => $id_jpn) or return;
    Shachi::Service::Resource->embed_title(
        db => $db, resources => $resource_jpn->as_list,
        language => $japanese, args => { fillin_english => 1 },
    );

    # メタデータの言語を日本語に
    $db->shachi->table('resource_metadata')->search({
        resource_id => $id_jpn,
        language_id => $english->id,
    })->update({
        $id_eng ? (resource_id => $id_eng) : (),
        language_id => $japanese->id,
    });

    if ( $id_eng ) {
        my $resource_eng = Shachi::Service::Resource->find_by_id(db => $db, id => $id_eng);
        Shachi::Service::Resource->embed_title(
            db => $db, resources => $resource_eng->as_list,
            language => $japanese, args => { fillin_english => 1 },
        );
        # relationを移行
        Shachi::Service::Resource::Metadata->update_resource_relation(
            db => $db,
            old => $resource_jpn->relation_value,
            new => $resource_eng->relation_value,
        );

        my $titles = $db->shachi->table('resource_metadata')->search({
            resource_id => $id_eng,
            metadata_name => METADATA_TITLE
        })->list->map(sub { $_->content })->to_a;
        $db->shachi->table('resource_metadata')->search({
            resource_id => $id_eng,
            metadata_name => METADATA_TITLE_ALTERNATIVE,
            content => { -in => $titles }
        })->delete;

        Shachi::Service::Resource->delete_by_id(db => $db, id => $id_jpn);
    } else {
        # タイトルだけは埋めておく
        Shachi::Service::Resource::Metadata->create(db => $db, args => {
            resource_id => $id_jpn, language_id => $english->id,
            metadata_name => METADATA_TITLE,
            content => $resource_jpn->title,
        });
    }
}


# investigate_alignment();

# identifier
# title <-> title_alternative
sub investigate_alignment {
    my $resources = $db->shachi->table('resource')->search({})->order_by('id asc')->list;
    Shachi::Service::Resource->embed_title(
        db => $db, resources => $resources, language => $english
    );
    my $resource_by_id = $resources->hash_by('id');

    my $japanese_resource_ids = {};
    my $alignments = {};
    foreach my $resource ( @$resources ) {
        warn $resource->id if $resource->id % 100 == 0;
        $japanese_resource_ids->{$resource->id} = 0 if $resource->title && $resource->title =~ /\p{Han}/;
        alignment_by_title($alignments, $resource);
        alignment_by_identifier($alignments, $resource);
    }
    warn scalar keys %$japanese_resource_ids;

    alignment_resource($alignments, $japanese_resource_ids);
    warn scalar grep { $_ } values %$japanese_resource_ids;

    # delete $japanese_resource_ids->{$_}
    #     for grep { ! $japanese_resource_ids->{$_} } keys %$japanese_resource_ids;

    # alignment_by_title($alignments, $_, 1) for @$resources;
    # alignment_resource($alignments, $japanese_resource_ids);
    # warn scalar grep { $_ } values %$japanese_resource_ids;

    foreach my $id ( keys %$japanese_resource_ids ) {
        if ( $japanese_resource_ids->{$id} ) {
            my $alternate_id = $japanese_resource_ids->{$id};
            printf "%d\t%d\t%s\t%s\n", $id, $alternate_id, $resource_by_id->{$id}->title,
                $resource_by_id->{$alternate_id}->title;
        } else {
            printf "%d\t\t%s\n", $id, $resource_by_id->{$id}->title;
        }
    }
}


sub alignment_resource {
    my ($alignments, $japanese_resource_ids) = @_;
    foreach my $key ( keys %$alignments ) {
        my $val = $alignments->{$key};
        if ( defined $japanese_resource_ids->{$key} ) {
            $japanese_resource_ids->{$key} = $val;
        } elsif ( defined $japanese_resource_ids->{$val} ) {
            $japanese_resource_ids->{$val} = $key;
        }
    }
}

sub alignment_by_title {
    my ($alignments, $resource, $is_loosely) = @_;
    # 4255はタイトルでの対応に失敗する
    return if $resource->id == 4255;
    return unless $resource->title;
    my $title = $resource->title;
    # $title =~ s/[\(（].+[\)）]// if $is_loosely;
    my $titles = $db->shachi->table('resource_metadata')->search({
        metadata_name => 'title_alternative',
        language_id   => $english->id,
        $is_loosely ? (content => { -like => $title . '%' }) : (content => $title),
    })->list;
    foreach my $title ( @$titles ) {
        my $alternate = _alternate_resource($resource, $title, $titles->size > 1) or next;
        $alignments->{$resource->id} = $alternate->resource_id;
    }
}

sub _alternate_resource {
    my ($resource, $alternate_title, $double_check) = @_;
    return if $resource->id == $alternate_title->resource_id;
    my $alternate_resource_title = $db->shachi->table('resource_metadata')->search({
        resource_id => $alternate_title->resource_id,
        metadata_name => 'title', language_id => $english->id,
    })->single or return;
    if ( $double_check ) {
        $db->shachi->table('resource_metadata')->search({
            resource_id => $resource->id, metadata_name => 'title_alternative',
            language_id => $english->id,
            content => $alternate_resource_title->content,
        })->single or return;
    }
    return $alternate_resource_title;
}

sub alignment_by_identifier {
    my ($alignments, $resource) = @_;
    # 既にtitle_alternativeでアライメントとれてる場合は終了
    return if  $alignments->{$resource->id};
    my $identifiers = $db->shachi->table('resource_metadata')->search({
        resource_id => $resource->id,
        metadata_name => 'identifier', language_id => $english->id,
    })->list;
    return unless $identifiers->size;

    foreach my $identifier ( @$identifiers ) {
        my $alternate_identifiers = $db->shachi->table('resource_metadata')->search({
            resource_id => { '!=' => $resource->id },
            metadata_name => 'identifier', language_id => $english->id,
            content => $identifier->content,
        })->list;
        next unless $alternate_identifiers->size == 1;
        $alignments->{$resource->id} = $alternate_identifiers->first->resource_id;
    }
}
