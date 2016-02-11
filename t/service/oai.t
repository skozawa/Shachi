package t::Shachi::Service::OAI;
use t::test;
use utf8;
use Shachi::Database;
use Shachi::Model::List;
use Shachi::Service::Resource;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::OAI';
}

sub get_record : Tests {
    truncate_db_with_setup;

    subtest 'get record' => sub {
        my $english = get_english;
        my $resource = create_resource;
        my $metadata_list = Shachi::Model::List->new(list => [ map {
            my $name = delete $_->{name};
            my $metadata = create_metadata(name => $name);
            create_resource_metadata(resource => $resource, metadata => $metadata, language => $english, %$_);
            $metadata;
        } (
            { name => 'title', content => 'test corpus' },
            { name => 'creator', content => 'Test Univ.' },
            { name => 'subject', content => 'Speech Synthesis' },
            { name => 'subject_linguisticField', value_id => create_metadata_value(value => 'phonetics')->id },
            { name => 'subject_monoMultilingual', value_id => create_metadata_value(value => 'monolingual')->id },
            { name => 'subject_resourceSubject', value_id => create_metadata_value(value => 'dictionary')->id },
            { name => 'description', content => 'corpus description' },
            { name => 'description_language', value_id => create_language(code => 'ita')->value_id },
            { name => 'description_price', content => '$500' },
            { name => 'description_input_device', value_id => create_metadata_value(value => 'mobile_phone')->id },
            { name => 'description_input_environment', value_id => create_metadata_value(value => 'office_room')->id },
            { name => 'description_speaking_style', value_id => create_metadata_value(value => 'read_speech')->id },
            { name => 'description_speech_mode', value_id => create_metadata_value(value => 'monologue')->id },
            { name => 'description_sampling_rate', content => 'sample rate' },
            { name => 'description_additional_data', value_id => create_metadata_value(value => 'multimodal_data')->id },
            { name => 'publisher', content => 'Test Univ.' },
            { name => 'contributor_author_motherTongue', value_id => create_metadata_value(value => 'native')->id },
            { name => 'contributor_author_dialect', value_id => create_metadata_value(value => 'dialect')->id },
            { name => 'contributor_author_level', value_id => create_metadata_value(value => 'amatuer')->id },
            { name => 'contributor_author_age', value_id => create_metadata_value(value => 'adult')->id },
            { name => 'contributor_author_gender', value_id => create_metadata_value(value => 'female')->id },
            { name => 'contributor_speaker_motherTongue', value_id => create_metadata_value(value => 'non_native')->id },
            { name => 'contributor_speaker_dialect', value_id => create_metadata_value(value => 'standard_dialect')->id },
            { name => 'contributor_speaker_level', value_id => create_metadata_value(value => 'professional')->id },
            { name => 'contributor_speaker_age', value_id => create_metadata_value(value => 'senior')->id },
            { name => 'contributor_speaker_gender', value_id => create_metadata_value(value => 'male')->id },
            { name => 'contributor_speaker_number', value_id => create_metadata_value(value => 'number_of_total_speakers')->id, description => '10' },
            { name => 'type', value_id => create_metadata_value(value => 'Sound')->id },
            { name => 'type_discourseType', value_id => create_metadata_value(value => 'narrative')->id },
            { name => 'type_linguisticType', value_id => create_metadata_value(value => 'primary_text')->id },
            { name => 'type_purpose', value_id => create_metadata_value(value => 'analysis')->id },
            { name => 'type_style', value_id => create_metadata_value(value => 'speech')->id },
            { name => 'type_form', value_id => create_metadata_value(value => 'fixed')->id },
            { name => 'type_sentence', value_id => create_metadata_value(value => 'long')->id },
            { name => 'type_annotation', value_id => create_metadata_value(value => 'plain')->id },
            { name => 'type_annotationSample', content => 'sample annotation' },
            { name => 'type_sample', content => 'data sample' },
            { name => 'identifier', content => 'corpus id' },
            { name => 'source', content => 'corpus source' },
            { name => 'coverage_temporal', content => 'coverage' },
            { name => 'rights', content => 'all right reserved' },
            { name => 'title_alternative', content => 'tco' },
            { name => 'date_created', content => '2001-01-01 2001-03-01' },
            { name => 'date_issued', content => '2001-04-01' },
            { name => 'date_modified', content => '2001-05-01' },
            { name => 'format_extent', content => '40K' },
            { name => 'format_medium', content => 'DVD' },
            { name => 'format_encoding', content => 'encode' },
            { name => 'format_markup', content => 'xml' },
            { name => 'format_functionality', content => 'func' },
            { name => 'coverage_spacial', content => 'sp' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isVersionOf')->id, description => 'T-000003: test corpus' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'hasVersion')->id, description => 'T-000007: test corpus 2' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isReplacedBy')->id, description => 'T-000002: old test corpus' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'replaces')->id, description => 'corpus for replace' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isRequiredBy')->id, description => 'D-000009: dictionary' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'requires')->id, description => 'D-000011: dic' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isPartOf')->id, description => 'part thesaurus' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'hasPart')->id, description => 'D-000012: dictionary version2' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isReferencedBy')->id, description => 'http://example.com/' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'references')->id, description => 'refer' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'isFormatOf')->id, description => 'dic format' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'hasFormat')->id, description => 'format' },
            { name => 'relation', value_id => create_metadata_value(value_type => 'conformsTo')->id, description => 'conforms' },
            { name => 'relation_utilization', content => 'corpus analysis' },
        ) ]);

        my $db = Shachi::Database->new;
        my ($resource_detail) = Shachi::Service::Resource->find_resource_detail(
            db => $db, id => $resource->id, language => $english,
            args => { metadata_list => $metadata_list, with_language => 1 },
        );

        my $doc = Shachi::Service::OAI->get_record(resource => $resource_detail);

        ok $doc->getElementsByTagName('SCRIPT');
        ok $doc->getElementsByTagName('responseDate');
        is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';
        ok $doc->getElementsByTagName('GetRecord');

        my $record = $doc->getElementsByTagName('record')->[0];
        ok $record;

        my $header = $record->getElementsByTagName('header')->[0];
        ok $header;
        is $header->getElementsByTagName('identifier')->[0]->textContent, 'oai:shachi.org:' . $resource->shachi_id;

        my $metadata = $record->getElementsByTagName('metadata')->[0];
        ok $metadata;
        my $olac = $metadata->getElementsByTagName('olac:olac')->[0];
        ok $olac;

        for (
            ['dc:title', 0, undef, 'test corpus'],
            ['dc:creator', 0, undef, 'Test Univ.'],
            ['dc:subject', 0, undef, 'Speech Synthesis'],
            ['dc:subject', 1, 'olac:code', 'phonetics'],
            ['dc:subject', 2, 'shachi:code', 'monolingual'],
            ['dc:subject', 3, 'shachi:code', 'dictionary'],
            ['dc:description', 0, undef, 'corpus description'],
            ['dc:description', 1, 'olac:code', 'ita'],
            ['dc:description', 2, 'olac:code', 'it'],
            ['dc:description', 3, undef, '$500'],
            ['dc:description', 4, 'shachi:code', 'mobile_phone'],
            ['dc:description', 5, 'shachi:code', 'office_room'],
            ['dc:description', 6, 'shachi:code', 'read_speech'],
            ['dc:description', 7, 'shachi:code', 'monologue'],
            ['dc:description', 8, undef, 'sample rate'],
            ['dc:description', 9, 'shachi:code', 'multimodal_data'],
            ['dc:publisher', 0, undef, 'Test Univ.'],
            ['dc:author', 0, 'shachi:code', 'native', 'dc:contributor'],
            ['dc:author', 1, 'shachi:code', 'dialect', 'dc:contributor'],
            ['dc:author', 2, 'shachi:code', 'amatuer', 'dc:contributor'],
            ['dc:author', 3, 'shachi:code', 'adult', 'dc:contributor'],
            ['dc:author', 4, 'shachi:code', 'female', 'dc:contributor'],
            ['dc:speaker', 0, 'shachi:code', 'non_native', 'dc:contributor'],
            ['dc:speaker', 1, 'shachi:code', 'standard_dialect', 'dc:contributor'],
            ['dc:speaker', 2, 'shachi:code', 'professional', 'dc:contributor'],
            ['dc:speaker', 3, 'shachi:code', 'senior', 'dc:contributor'],
            ['dc:speaker', 4, 'shachi:code', 'male', 'dc:contributor'],
            ['dc:speaker', 5, 'shachi:code', 'number_of_total_speakers', 'dc:contributor'],
            ['dc:speaker', 5, undef, '10', 'dc:contributor'],
            ['dc:type', 0, undef, 'Sound'],
            ['dc:type', 1, 'olac:code', 'narrative'],
            ['dc:type', 2, 'olac:code', 'primary_text'],
            ['dc:type', 3, 'shachi:code', 'analysis'],
            ['dc:type', 4, 'shachi:code', 'speech'],
            ['dc:type', 5, 'shachi:code', 'fixed'],
            ['dc:type', 6, 'shachi:code', 'long'],
            ['dc:type', 7, 'shachi:code', 'plain'],
            ['dc:type', 8, undef, 'sample annotation'],
            ['dc:type', 9, undef, 'data sample'],
            ['dc:identifier', 0, undef, 'corpus id'],
            ['dc:source', 0, undef, 'corpus source'],
            ['dc:coverage', 0, undef, 'coverage'],
            ['dc:rights', 0, undef, 'all right reserved'],
            ['dcterm:alternative', 0, undef, 'tco'],
            ['dcterm:created', 0, undef, '2001-01-01 2001-03-01'],
            ['dcterm:issued', 0, undef, '2001-04-01'],
            ['dcterm:modified', 0, undef, '2001-05-01'],
            ['dcterm:extent', 0, undef, '40K'],
            ['dcterm:medium', 0, undef, 'DVD'],
            ['dc:format', 0, undef, 'encode'],
            ['dc:format', 1, undef, 'xml'],
            ['dc:format', 2, undef, 'func'],
            ['dcterm:spatial', 0, undef, 'sp'],
            ['dcterm:isVersionOf', 0, undef, 'oai:shachi.org:T-000003'],
            ['dcterm:hasVersion', 0, undef, 'oai:shachi.org:T-000007'],
            ['dcterm:isReplacedBy', 0, undef, 'oai:shachi.org:T-000002'],
            ['dcterm:replaces', 0, undef, 'corpus for replace'],
            ['dcterm:isRequiredBy', 0, undef, 'oai:shachi.org:D-000009'],
            ['dcterm:requires', 0, undef, 'oai:shachi.org:D-000011'],
            ['dcterm:isPartOf', 0, undef, 'part thesaurus'],
            ['dcterm:hasPart', 0, undef, 'oai:shachi.org:D-000012'],
            ['dcterm:isReferencedBy', 0, undef, 'http://example.com/'],
            ['dcterm:references', 0, undef, 'refer'],
            ['dcterm:isFormatOf', 0, undef, 'dic format'],
            ['dcterm:hasFormat', 0, undef, 'format'],
            ['dcterm:conformsTo', 0, undef, 'conforms'],
            ['dc:relation', 0, undef, 'corpus analysis'],
        ) {
            my $parent = $_->[5] ? $olac->getElementsByTagName($_->[5])->[0] : $olac;
            my $element = $parent->getElementsByTagName($_->[0])->[$_->[1]];
            my $value = $_->[2] ? $element->getAttribute($_->[2]) : $element->textContent;
            is $value , $_->[3], $_->[0];
        }
    };

    subtest 'no metadata resource' => sub {
        my $resource = create_resource;
        my $doc = Shachi::Service::OAI->get_record(resource => $resource);

        ok $doc->getElementsByTagName('SCRIPT');
        ok $doc->getElementsByTagName('responseDate');
        is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

        ok $doc->getElementsByTagName('GetRecord');

        my $record = $doc->getElementsByTagName('record')->[0];
        ok $record;

        my $header = $record->getElementsByTagName('header')->[0];
        ok $header;
        is $header->getElementsByTagName('identifier')->[0]->textContent, 'oai:shachi.org:' . $resource->shachi_id;

        my $metadata = $record->getElementsByTagName('metadata')->[0];
        ok $metadata;
        my $olac = $metadata->getElementsByTagName('olac:olac')->[0];
        ok $olac;
        is $olac->getAttribute('xmlns:olac'), 'http://www.language-archives.org/OLAC/1.1/';
        is $olac->getAttribute('xmlns:dc'), 'http://purl.org/dc/elements/1.1/';
        is $olac->getAttribute('xmlns:dcterms'), 'http://purl.org/dc/terms/';
    };
}

sub identify : Tests {
    my $doc = Shachi::Service::OAI->identify;

    ok $doc->getElementsByTagName('SCRIPT');
    ok $doc->getElementsByTagName('responseDate');
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

    ok $doc->getElementsByTagName('Identify');
    for ( (
        ['repository', 'SHACHI'],
        ['baseURL', 'http://shachi.org/olac/oai2'],
        ['protocolVersion', '2.0'],
        ['adminEmail', 'mailto:admin@shachi.org'],
        ['earliestDatestamp', '2000-01-01T00:00:00Z'],
        ['deletedRecord', 'no'],
        ['granularity', 'YYYY-MM-DDThh:mm:ssZ']
    ) ) {
        is $doc->getElementsByTagName($_->[0])->[0]->textContent, $_->[1], $_->[0];
    }

    is $doc->getElementsByTagName('description')->size, 2;

    my $identifier = $doc->getElementsByTagName('oai-identifier')->[0];
    ok $identifier;
    is $identifier->getAttribute('xmlns'), 'http://www.openarchives.org/OAI/2.0/oai-identifier';
    is $identifier->getAttribute('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance';
    is $identifier->getAttribute('xsi:schemaLocation'), 'http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd';

    for ( (
        ['scheme', 'oai'],
        ['repositoryIdentifier', 'shachi.org'],
        ['delemiter', ':'],
        ['sampleIdentifier', 'oai:shachi.org:N-000001']
    ) ) {
        is $identifier->getElementsByTagName($_->[0])->[0]->textContent, $_->[1], $_->[0];
    }

    my $olac_archive = $doc->getElementsByTagName('olac-archive')->[0];
    ok $olac_archive;
    is $olac_archive->getAttribute('xmlns'), 'http://www.language-archives.org/OLAC/1.0/olac-archive';
    is $olac_archive->getAttribute('xmlns:xsi'), 'http://www.w3.org/2001/XMLSchema-instance';
    is $olac_archive->getAttribute('xsi:schemaLocation'), 'http://www.language-archives.org/OLAC/1.0/olac-archive http://www.language-archives.org/OLAC/1.0/olac-archive.xsd';
    is $olac_archive->getAttribute('type'), 'institutional';

    for ( (
        ['archiveURL', 'http://shachi.org/'],
        ['curator', '清貴, 内元 (Uchimoto Kiyotaka); 仁美, 遠山 (Tohyama Hitomi); 俊介, 小澤 (Kozawa Shunsuke); 茂樹, 松原 (Matsubara Shigeki)'],
        ['curatorEmail', 'mailto:admin@shachi.org'],
        ['institution', 'The National Institute of Information and Communications Technology (NICT); Nagoya University'],
        ['institutionURL', 'http://www.nict.go.jp/; http://www.nagoya-u.ac.jp/'],
        ['shortLocation', 'Kyoto, Japan; Nagoya, Japan'],
        ['synopsis', 'The purpose of the database is to investigate languages, tag sets, and formats compiled in language resources throughout the world, to systematically store language resource metadata, to create a search function for this information, and to ultimately utilize all this for a more efficient development of language resources.'],
        ['access', 'Every resource described by the SHACHI metadata repository is a public Web page that may be accessed without restriction.']
    ) ) {
        is $olac_archive->getElementsByTagName($_->[0])->[0]->textContent, $_->[1], $_->[0];
    }
}

sub list_identifiers : Tests {
    truncate_db;

    subtest 'no resources' => sub {
        my $db = Shachi::Database->new;
        my $doc = Shachi::Service::OAI->list_identifiers(db => $db);

        ok $doc->getElementsByTagName('SCRIPT');
        ok $doc->getElementsByTagName('responseDate');
        is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

        my $list_identifiers = $doc->getElementsByTagName('ListIdentifiers')->[0];
        ok $list_identifiers;

        my $headers = $list_identifiers->getElementsByTagName('header');
        is $headers->size, 0;
    };

    subtest 'resource identifiers' => sub {
        create_resource(resource_subject => $_)
            for qw/corpus dictionary glossary thesaurus test/;

        my $db = Shachi::Database->new;
        my $doc = Shachi::Service::OAI->list_identifiers(db => $db);

        ok $doc->getElementsByTagName('SCRIPT');
        ok $doc->getElementsByTagName('responseDate');
        is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

        my $list_identifiers = $doc->getElementsByTagName('ListIdentifiers')->[0];
        ok $list_identifiers;

        my $headers = $list_identifiers->getElementsByTagName('header');
        is $headers->size, 5;

        $headers->[0]->getElementsByTagName('identifier')->[0]->textContent, 'C-000001';
        $headers->[1]->getElementsByTagName('identifier')->[0]->textContent, 'D-000002';
        $headers->[2]->getElementsByTagName('identifier')->[0]->textContent, 'G-000003';
        $headers->[3]->getElementsByTagName('identifier')->[0]->textContent, 'T-000004';
        $headers->[4]->getElementsByTagName('identifier')->[0]->textContent, 'O-000005';
    };
}

sub list_metadata_formats : Tests {
    my $doc = Shachi::Service::OAI->list_metadata_formats;

    ok $doc->getElementsByTagName('SCRIPT');
    ok $doc->getElementsByTagName('responseDate');
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

    ok $doc->getElementsByTagName('ListMetadataFormats');

    my $format = $doc->getElementsByTagName('metadataFormat')->[0];
    ok $format;

    for ( (
        ['metadataPrefix', 'olac' ],
        ['schema', 'http://www.language-archives.org/OLAC/1.0/olac.xsd' ],
        ['metadataNamespace', 'http://www.language-archives.org/OLAC/1.0/' ],
    ) ) {
        is $format->getElementsByTagName($_->[0])->[0]->textContent, $_->[1], $_->[0];
    }
}

sub list_sets : Tests {
    my $doc = Shachi::Service::OAI->list_sets;

    ok $doc->getElementsByTagName('SCRIPT');
    ok $doc->getElementsByTagName('responseDate');
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/olac/oai2';

    ok $doc->getElementsByTagName('ListSets');
}
