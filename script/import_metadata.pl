use strict;
use warnings;
use utf8;
use Data::Dumper;
use XML::LibXML;
use Getopt::Long;
use List::MoreUtils qw/any/;
use Furl;
use Shachi::Database;
use Shachi::Model::Metadata;
use Shachi::Service::Annotator;
use Shachi::Service::Language;
use Shachi::Service::Resource;
use Shachi::Service::Resource::Metadata;

$ENV{PLACK_ENV} ||= 'development';

my $target;
my $debug;
GetOptions(
    'target=s' => \$target,
    'debug'    => \$debug,
);

my $target_config = {
    ELRA => {
        url => 'http://catalog.elra.info/elrac/elra_catalogue.xml',
        xml => 'elra_catalogue.xml',
        annotator_id => 4,
        status => 'limited_by_ELRA',
    },
    LDC  => {
        url => 'https://catalog.ldc.upenn.edu/olac/ldc_catalog.xml',
        xml => 'ldc_catalog.xml',
        annotator_id => 32,
        status => 'limited_by_LDC',
    },
};

my $metadata_config = {
    title        => { name => 'title' },
    description  => { name => 'description' },
    coverage     => { name => 'coverage_temporal', multi => 1 },
    rights       => { name => 'rights', multi => 1 },
    publisher    => { name => 'publisher', multi => 1, exchange => 1 },
    accessRights => { name => 'rights', multi => 1 },
    created      => { name => 'date_created' },
    issued       => { name => 'date_issued' },
    modified     => { name => 'date_modified', multi => 1 },
    medium       => { name => 'format_medium', multi => 1, exchange => 1 },
    extent       => { name => 'format_extent', multi => 1 },
    type         => { name => '', type => 1 },
    subject      => { name => 'subject', type => 1 },
    ## データなし
    # creator     => 'creator',
    # source      => 'source',
    # relation    => 'relation',
    ## 使い方不明
    # contributor  => { name => 'contributor', target => 'description', multi => 1 },
    # date        => '',
    # abstract    => METADATA_DESCRIPTION,
    # available   => 'date_issued',
};

my $type_map = {
    # http://www.language-archives.org/REC/olac-extensions.html
    'olac:language' => '',
    'olac:linguistic-field' => 'subject_linguisticField',
    'olac:linguistic-type' => 'type_linguisticType',
    'olac:role' => 'contributor',
    'olac:discourse-type' => 'type_discourseType',
    # http://dublincore.org/documents/dcmi-terms/#H7
    'dcterms:DCMIType' => 'type',
};


my $config = $target_config->{$target} or die 'target: ELRA or LDC';

my $doc = do {
    if ( -f $config->{xml} ) {
        XML::LibXML->load_xml(location => $config->{xml});
    } else {
        my $furl = Furl->new(timeout => 600);
        my $res = $furl->get($config->{url});
        die 'http request error:', $res->status_line, "\t", $config->{url} unless $res->is_success;
        XML::LibXML->load_xml(string => $res->content);
    }
};

my @records = $doc->getElementsByTagName('oai:record');

my $db = Shachi::Database->new;
my $english = Shachi::Service::Language->find_by_code(db => $db, code => 'eng');
my $annotator = Shachi::Service::Annotator->find_by_id(db => $db, id => $config->{annotator_id});

die 'Not Found english' unless $english;
die 'Not Found annotator' unless $annotator;


my $counts = {};
warn scalar @records;
foreach ( @records ) {
    my $record = Record->new( node => $_ );
    update($record);
}

warn 'All Resources: ', scalar @records;
warn 'New Resources: ', $counts->{new} || 0;
warn 'Update Resources: ', $counts->{update} || 0;

sub update {
    my ($record) = @_;

    my $res = search_record_resource($record);
    # identifierで検索してなかった場合は新規に作成
    unless ( $res->{resource_id} ) {
        $counts->{new}++;
        if ( $debug ) {
            my $title = $record->title->[0] ? $record->title->[0]->{content} : '';
            print '[NEW RESOURCE]', $title, "\n";
            return;
        }
        my $resource = Shachi::Service::Resource->create(db => $db, args => {
            annotator_id => $annotator->id,
            status       => $config->{status},
        });
        $res->{resource_id} = $resource->id;
    }

    unless ( $debug ) {
        # LDCからインポートした古いrightsに関するデータを削除
        # delete_old_ldc_rights($res->{resource_id});
    }

    my ($resource, $metadata_list) = Shachi::Service::Resource->find_resource_detail(
        db => $db, id => $res->{resource_id}, language => $english
    );

    my $data = [];
    foreach my $name ( sort keys %$metadata_config ) {
        push @$data, @{get_new_metadata($resource, $record, $name)};
    }
    push @$data, @{get_new_language($resource, $record)};
    push @$data, @{get_new_format($resource, $record)};
    push @$data, @{get_new_identifier($resource, $record)};

    foreach my $data ( @$data ) {
        print join("\t", map { $data->{$_} || () } qw/metadata_name content description value_id/), "\n";
    }

    $counts->{update}++ if @$data;

    unless ( $debug ) {
        my $has_update_by_name = +{ map { $_->{metadata_name} => 1 } @$data };
        # 単一のメタデータの場合は入れ替えるので削除する
        my $update_single_metadata_names = [ map {
            my $config = $metadata_config->{$_};
            !$config->{type} && !$config->{multi} &&
                $has_update_by_name->{$config->{name}} ? $config->{name} : ()
            } keys %$metadata_config ];
        delete_metadata_by_names($resource->id, $update_single_metadata_names);
        # publisher, medium などは入れ替えるので予め削除する
        my $exchange_metadata_names = [ map {
            my $config = $metadata_config->{$_};
            $config->{exchange} && $has_update_by_name->{$config->{name}} ? $config->{name} : ()
        } keys %$metadata_config ];
        delete_metadata_by_names($res->{resource_id}, $exchange_metadata_names);

        $db->shachi->table('resource_metadata')->insert_multi($data) if @$data;
        Shachi::Service::Resource->update_modified(db => $db, id => $resource->id) if @$data;
    }
}

sub get_new_metadata {
    my ($resource, $record, $olac_name, $args) = @_;
    $args ||= {};

    my $config = $metadata_config->{$olac_name} or return [];
    my $items = $record->$olac_name;
    return [] unless @$items;

    if ( $config->{type} ) {
        return _get_new_metadata_type($resource, $items, $config);
    } elsif ( $config->{multi} ) {
        return _get_new_metadata_multi($resource, $items, $config);
    } else {
        return _get_new_metadata_single($resource, $items, $config);
    }
}

sub _get_new_metadata_single {
    my ($resource, $items, $config) = @_;
    my $metadata_list = $resource->metadata_list_by_name($config->{name});
    my $target = $config->{target} || 'content';

    my $new = do {
        if ( $config->{name} eq 'description') {
            join "\n", map { $_->{content} ? $_->{content} || () : () } @$items;
        } elsif ( $config->{name} eq 'date_created' ) {
            $items->[0]->{content} . ' 0000-00-00';
        } else {
            $items->[0]->{content};
        }
    };
    my $current = $metadata_list->[0] ? $metadata_list->[0]->$target || '' : '';
    my $res = [];
    if ( $new eq $current ) {
        print "[EXISTS]", $config->{name}, "\t", $new, "\n" if $debug;
    } else {
        print "[NEW]", $config->{name}, "\t", $new, "\t", $current, "\n" if $debug;
        push @$res, create_data($resource, $config->{name}, { $target => $new });
    }

    return $res;
}

sub _get_new_metadata_multi {
    my ($resource, $items, $config) = @_;
    my $metadata_list = $resource->metadata_list_by_name($config->{name});
    my $target = $config->{target} || 'content';

    my $res = [];
    my $has_new_metadata = 0;
    foreach my $item ( @$items ) {
        my $content = $item->{content} or next;
        $content =~ s/^Distribution: // if $config->{name} eq 'format_medium';
        if ( any { $_->$target && $content eq $_->$target } @$metadata_list ) {
            print '[EXISTS]', $config->{name}, "\t", $content, "\n" if $debug;
            # 入れ替えする場合は重複メタデータも保持
            push @$res, create_data($resource, $config->{name}, { $target => $content }) if $config->{exchange};
        } else {
            print '[NEW]', $config->{name}, "\t", $content, "\n" if $debug;
            $has_new_metadata = 1;
            push @$res, create_data($resource, $config->{name}, { $target => $content });
        }
    }
    # 入れ替えする場合は新規メタデータがない場合は削除
    $res = [] if $config->{exchange} && !$has_new_metadata;
    return $res;
}

sub _get_new_metadata_type {
    my ($resource, $items, $config) = @_;

    my $res = [];
    foreach my $item ( @$items ) {
        next unless $item->{type};
        my $metadata_name = $type_map->{$item->{type}} or next;
        my $value = $item->{code} || $item->{content} or next;
        my $metadata_list = $resource->metadata_list_by_name($metadata_name);
        if ( any { $_->value && $value eq $_->value->value } @$metadata_list ) {
            print '[EXISTS]', $item->{type}, "\t", $metadata_name, "\t", $value, "\n" if $debug;
        } else {
            print '[NEW]', $item->{type}, "\t", $metadata_name, "\t", $value, "\n" if $debug;

            my $metadata = $db->shachi->table('metadata')->search({
                name => $metadata_name,
            })->single or next;
            my $metadata_value = $db->shachi->table('metadata_value')->search({
                value_type => $metadata->value_type,
                value      => $value,
            })->single or next;
            push @$res, create_data($resource, $metadata_name, { value_id => $metadata_value->id });
        }
    }
    return $res;
}

sub create_data {
    my ($resource, $name, $args) = @_;
    return +{
        resource_id   => $resource->id,
        language_id   => $english->id,
        metadata_name => $name,
        value_id      => $args->{value_id} || 0,
        content       => $args->{content} || '',
        description   => $args->{description} || '',
    };
}

sub get_new_language {
    my ($resource, $record, $args) = @_;
    $args ||= {};

    my $items = $record->language;
    return [] unless @$items;
    my $metadata_list = $resource->metadata_list_by_name('language');

    my $res = [];
    my $languages = [ map { split /, /, $_->{content} } @$items ];
    foreach my $content ( @$languages ) {
        if ( any { $_->value && $content eq $_->value->value} @$metadata_list ) {
            print '[EXISTS]language', "\t", $content, "\n" if $debug;
        } else {
            print '[NEW]language', "\t", $content, "\n" if $debug;
            my $lang = $db->shachi->table('language')->search({
                name => $content,
            })->single;
            next unless $lang;
            push @$res, create_data($resource, 'language', { value_id => $lang->value_id });
        }
    }
    return $res;
}

sub get_new_format {
    my ($resource, $record, $args) = @_;
    $args ||= {};

    my $items = $record->format;
    return [] unless @$items;

    my $res = [];
    foreach my $item ( @$items ) {
        next unless $item->{content};
        if ( $item->{content} =~ /Sampling Rate\s?:\s?(\d+)/ ) {
            my $content = ($1 / 1000) . ' kHz';
            my $metadata_list = $resource->metadata_list_by_name('description_sampling_rate');
            if ( any { $content eq $_->content } @$metadata_list ) {
                print '[EXISTS]sampling_rate', "\t", $content, "\n" if $debug;
            } else {
                print '[NEW]sampling_rate', "\t", $content, "\n" if $debug;
                push @$res, create_data($resource, 'description_sampling_rate', { content => $content });
            }
        }
    }
    return $res;
}

sub get_new_identifier {
    my ($resource, $record, $args) = @_;
    $args ||= {};

    my $items = $record->identifier;
    return [] unless @$items;
    my $metadata_list = $resource->metadata_list_by_name('identifier');

    my $res = [];
    foreach my $item ( @$items ) {
        next unless $item->{content};
        if ( $item->{content} =~ /^ISLRN\s?:\s*?([0-9-]+)/ ) {
            my $id = $1;
            my $metadata = $resource->metadata_list_by_name('identifier_islrn')->[0];
            if ( $metadata && $metadata->content eq $id ) {
                print '[EXISTS]identifier_islrn', "\t", $id, "\n" if $debug;
            } else {
                print '[NEW]identifier_islrn', "\t", $id, "\n" if $debug;
                push @$res, create_data($resource, 'identifier_islrn', { content => $id });
            }
        } else {
            my $content = $item->{content};
            $content =~ s/^ISBN: /ISBN:/;
            if ( any { $content eq $_->content } @$metadata_list ) {
                print '[EXISTS]identifier', "\t", $content, "\n" if $debug;
            } else {
                print '[NEW]identifer', "\t", $content, "\n" if $debug;
                push @$res, create_data($resource, 'identifier', { content => $content });
            }
        }
    }
    return $res;
}

sub delete_old_ldc_rights {
    my ($resource_id) = @_;
    $db->shachi->table('resource_metadata')->search({
        resource_id => $resource_id,
        metadata_name => 'rights',
        language_id => $english->id,
        -or => [
            { content => { -like => 'Licensing Instructions for%' } },
            { content => { -like => '%http://www.ldc.upenn.edu/Catalog/nonMember%' } },
            { content => { -like => '%http://www.ldc.upenn.edu/Catalog/standardMember.html%' } },
            { content => { -like => '%http://www.ldc.upenn.edu/Catalog/subscriptionMember.html%' } },
        ],
    })->delete;
}

sub delete_metadata_by_names {
    my ($resource_id, $names) = @_;
    return unless $names && @$names;
    $db->shachi->table('resource_metadata')->search({
        resource_id => $resource_id,
        language_id => $english->id,
        metadata_name => { -in => $names },
    })->delete;
}

sub search_record_resource {
    my ($record) = @_;
    my $res = {
        resource_id => 0,
        identifier  => {},
        title       => {},
    };
    foreach my $identifier ( @{$record->identifier} ) {
        my $content = $identifier->{content} or next;
        my $metadata_list = $db->shachi->table('resource_metadata')->search({
            metadata_name => METADATA_IDENTIFIER,
            content       => $content,
        })->list;
        if ( $metadata_list->size ) {
            $res->{identifier}->{$content} = $metadata_list->first->resource_id;
            $res->{resource_id} = $metadata_list->first->resource_id;
        }
    }
    # foreach my $title ( @{$record->title} ) {
    #     my $content = $title->{content} or next;
    #     my $metadata_list = $db->shachi->table('resource_metadata')->search({
    #         metadata_name => METADATA_TITLE,
    #         content       => $content,
    #     })->list;
    #     if ( $metadata_list->size ) {
    #         $res->{title}->{$content} = $metadata_list->first->resource_id;
    #         $res->{resource_id} ||= $metadata_list->first->resource_id;
    #     }
    # }
    return $res;
}


package Record;
use strict;
use warnings;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/node/],
    ro_lazy => [qw/
        oai_identifier
        metadata

        title creator subject description publisher
        contributor date type format identifier
        source language relation coverage rights

        abstract accessRights available created issued modified medium extent
        bibliographicCitation license provenance rightsHolder
    /],
);

sub _build_oai_identifier {
    $_[0]->node->findnodes('oai:header/oai:identifier')->string_value;
}
sub _build_metadata {
    [ $_[0]->node->getElementsByTagName('oai:metadata') ]->[0];
}

sub _build_title       { $_[0]->get_values('dc:title') }
sub _build_creator     { $_[0]->get_values('dc:creator') }
sub _build_subject     { $_[0]->get_values('dc:subject') }
sub _build_description { $_[0]->get_values('dc:description') }
sub _build_publisher   { $_[0]->get_values('dc:publisher') }
sub _build_contributor { $_[0]->get_values('dc:contributor') }
sub _build_date        { $_[0]->get_values('dc:date') }
sub _build_type        { $_[0]->get_values('dc:type') }
sub _build_format      { $_[0]->get_values('dc:format') }
sub _build_identifier  { $_[0]->get_values('dc:identifier') }
sub _build_source      { $_[0]->get_values('dc:source') }
sub _build_language    { $_[0]->get_values('dc:language') }
sub _build_relation    { $_[0]->get_values('dc:relation') }
sub _build_coverage    { $_[0]->get_values('dc:coverage') }
sub _build_rights      { $_[0]->get_values('dc:rights') }

sub _build_abstract { $_[0]->get_values('dcterms:abstract') }
sub _build_accessRights { $_[0]->get_values('dcterms:accessRights') }
sub _build_available { $_[0]->get_values('dcterms:available') }
sub _build_created { $_[0]->get_values('dcterms:created') }
sub _build_issued { $_[0]->get_values('dcterms:issued') }
sub _build_modified { $_[0]->get_values('dcterms:modified') }
sub _build_medium { $_[0]->get_values('dcterms:medium') }
sub _build_extent { $_[0]->get_values('dcterms:extent') }

sub _build_bibliographicCitation { $_[0]->get_values('dcterms:bibliographicCitation') }
sub _build_license { $_[0]->get_values('dcterms:license') }
sub _build_provenance { $_[0]->get_values('dcterms:provenance') }
sub _build_rightsHolder { $_[0]->get_values('dcterms:rightsHolder') }


sub get_values {
    my ($self, $tag) = @_;
    return [] unless $self->metadata;
    my $values = [];
    foreach my $node ( $self->metadata->getElementsByTagName($tag) ) {
        my $value = {};
        $value->{$_->name} = $_->value for $node->attributes;
        my $content = $self->normalize($node->textContent);
        $value->{content} = $content if $content;
        push @$values, $value if %$value;
    }
    return $values;
}

sub normalize {
    my ($self, $string) = @_;
    return unless $string;
    $string =~ s/^\s+|\s+$//;
    $string =~ s/  / /;
    $string;
}

1;
