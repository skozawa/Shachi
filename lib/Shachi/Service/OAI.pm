package Shachi::Service::OAI;
use strict;
use warnings;
use utf8;
use Smart::Args;
use XML::LibXML;
use DateTime;
use DateTime::Format::W3CDTF;

my $lang_code_map = {
    'aar' => 'aa',
    'abk' => 'ab',
    'ave' => 'ae',
    'afr' => 'af',
    'amh' => 'am',
    'ara' => 'ar',
    'asm' => 'as',
    'aym' => 'ay',
    'aze' => 'az',
    'bak' => 'ba',
    'bel' => 'be',
    'bul' => 'bg',
    'bis' => 'bi',
    'ben' => 'bn',
    'bod' => 'bo',
    'bre' => 'br',
    'bos' => 'bs',
    'cat' => 'ca',
    'che' => 'ce',
    'cha' => 'ch',
    'cos' => 'co',
    'ces' => 'cs',
    'chu' => 'cu',
    'chv' => 'cv',
    'cym' => 'cy',
    'dan' => 'da',
    'deu' => 'de',
    'dzo' => 'dz',
    'ell' => 'el',
    'eng' => 'en',
    'epo' => 'eo',
    'spa' => 'es',
    'est' => 'et',
    'eus' => 'eu',
    'fas' => 'fa',
    'fin' => 'fi',
    'fij' => 'fj',
    'fao' => 'fo',
    'fra' => 'fr',
    'fry' => 'fy',
    'gle' => 'ga',
    'gla' => 'gd',
    'glg' => 'gl',
    'grn' => 'gn',
    'guj' => 'gu',
    'glv' => 'gv',
    'heb' => 'he',
    'hin' => 'hi',
    'hmo' => 'ho',
    'hrv' => 'hr',
    'hun' => 'hu',
    'hye' => 'hy',
    'her' => 'hz',
    'ina' => 'ia',
    'ind' => 'id',
    'ile' => 'ie',
    'ipk' => 'ik',
    'isl' => 'is',
    'ita' => 'it',
    'iku' => 'iu',
    'jpn' => 'ja',
    'jav' => 'jw',
    'kat' => 'ka',
    'kik' => 'ki',
    'kua' => 'kj',
    'kaz' => 'kk',
    'kal' => 'kl',
    'khm' => 'km',
    'kan' => 'kn',
    'kor' => 'ko',
    'kas' => 'ks',
    'kur' => 'ku',
    'kom' => 'kv',
    'cor' => 'kw',
    'kir' => 'ky',
    'lat' => 'la',
    'ltz' => 'lb',
    'lin' => 'ln',
    'lao' => 'lo',
    'lit' => 'lt',
    'lav' => 'lv',
    'mlg' => 'mg',
    'mah' => 'mh',
    'mri' => 'mi',
    'mkd' => 'mk',
    'mal' => 'ml',
    'mon' => 'mn',
    'mol' => 'mo',
    'mar' => 'mr',
    'msa' => 'ms',
    'mlt' => 'mt',
    'mya' => 'my',
    'nau' => 'na',
    'nob' => 'nb',
    'nde' => 'nd',
    'nep' => 'ne',
    'ndo' => 'ng',
    'nld' => 'nl',
    'nno' => 'nn',
    'nor' => 'no',
    'nbl' => 'nr',
    'nav' => 'nv',
    'nya' => 'ny',
    'oci' => 'oc',
    'orm' => 'om',
    'ori' => 'or',
    'oss' => 'os',
    'pan' => 'pa',
    'pli' => 'pi',
    'pol' => 'pl',
    'pus' => 'ps',
    'por' => 'pt',
    'que' => 'qu',
    'roh' => 'rm',
    'run' => 'rn',
    'ron' => 'ro',
    'rus' => 'ru',
    'kin' => 'rw',
    'san' => 'sa',
    'srd' => 'sc',
    'snd' => 'sd',
    'sme' => 'se',
    'sag' => 'sg',
    'sin' => 'si',
    'slk' => 'sk',
    'slv' => 'sl',
    'smo' => 'sm',
    'sna' => 'sn',
    'som' => 'so',
    'sqi' => 'sq',
    'srp' => 'sr',
    'ssw' => 'ss',
    'sot' => 'st',
    'sun' => 'su',
    'swe' => 'sv',
    'swa' => 'sw',
    'tam' => 'ta',
    'tel' => 'te',
    'tgk' => 'tg',
    'tha' => 'th',
    'tuk' => 'tk',
    'tgl' => 'tl',
    'tsn' => 'tn',
    'tso' => 'ts',
    'tat' => 'tt',
    'twi' => 'tw',
    'tah' => 'ty',
    'uig' => 'ug',
    'ukr' => 'uk',
    'urd' => 'ur',
    'uzb' => 'uz',
    'vie' => 'vi',
    'vol' => 'vo',
    'wol' => 'wo',
    'xho' => 'xh',
    'yid' => 'yi',
    'zha' => 'za',
    'zho' => 'zh',
    'zul' => 'zu',
};
my $w3c = DateTime::Format::W3CDTF->new;
sub _format_datetime {
    my ($dt) = @_;
    $w3c->format_datetime($dt);
}

sub _create_xml_base {
    my ($verb) = @_;

    my $now = DateTime->now;

    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    my $oai = _addChild($doc, $doc, 'OAI-PMH', { attributes => {
        'xmlns' => 'http://www.openarchives.org/OAI/2.0/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
    } });
    _addChildren($doc, $oai, [
        ['SCRIPT'],
        ['responseDate', { value => _format_datetime($now) }],
        ['request', { value => 'http://shachi.org/olac/oai2', attributes => { verb => $verb } } ]
    ]);

    return ($doc, $oai);
}

sub _addChild {
    my ($doc, $parent, $name, $args) = @_;
    $args ||= {};

    my $child = $doc->createElement($name);
    $child->appendText($args->{value}) if $args->{value};
    while (my ($key, $val) = each %{$args->{attributes} || {}}) {
        $child->setAttribute($key, $val);
    }
    $parent->addChild($child);
    return $child;
}

sub _addChildren {
    my ($doc, $parent, $children) = @_;
    _addChild($doc, $parent, @$_) for @$children;
}

sub _resource_header {
    my ($doc, $resource) = @_;
    my $header = $doc->createElement('header');
    _addChild($doc, $header, 'identifier', { value => sprintf 'oai:shachi.org:%s', $resource->shachi_id });
    _addChild($doc, $header, 'datestamp', { value => _format_datetime($resource->modified) });
    return $header;
}

sub _resource_metadata {
    my ($doc, $resource) = @_;
    my $metadata = $doc->createElement('metadata');
    my $olac = _addChild($doc, $metadata, 'olac:olac', { attributes => {
        'xmlns:olac'    => 'http://www.language-archives.org/OLAC/1.1/',
        'xmlns:dc'      => 'http://purl.org/dc/elements/1.1/',
        'xmlns:dcterms' => 'http://purl.org/dc/terms/',
        'xmlns:shachi'  => 'http://shachi.org/olac/',
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => join(
            '',
            'http://www.language-archives.org/OLAC/1.1/',
            'http://www.language-archives.org/OLAC/1.1/olac.xsd',
            'http://shachi.org/olac/',
            'http://shachi.org/olac/shachi.xsd',
        )
    } });
    foreach my $metadata_map ( @{resource_metadata_map()} ) {
        my $metadata_list = $resource->metadata_list_by_name($metadata_map->{name}) or next;
        foreach my $resource_metadata ( @$metadata_list ) {
            if ( $metadata_map->{value_type} ) {
                my $name = $metadata_map->{value_type} . ':' . $resource_metadata->value->value_type;
                my $content = $resource_metadata->description;
                if ( $content =~ /^([CTGDON]-(?:\d{6})): / ) {
                    $content = 'oai:shachi.org:' . $1;
                }
                _addChild($doc, $olac, $name, { value => $content });
            } elsif ( $metadata_map->{type} ) {
                my $code = do {
                    if ( $metadata_map->{type} eq 'olac:language' ) {
                        $lang_code_map->{$resource_metadata->language->code};
                    } elsif ( $metadata_map->{type} eq 'olac:ISO639-3' ) {
                        $resource_metadata->language->code;
                    } else {
                        $resource_metadata->value->value;
                    }
                } or next;
                _addChild($doc, $olac, $metadata_map->{tag}, { attributes => {
                    'xsi:type' => $metadata_map->{type},
                    $metadata_map->{code} => $code,
                } });
            } else {
                my $value = $metadata_map->{value} ?
                    $resource_metadata->value->value : $resource_metadata->content;
                _addChild($doc, $olac, $metadata_map->{tag}, { value => $value });
            }
        }
    }
    return $metadata;
}

sub resource_metadata_map {
    return [
        { name => 'title', tag => 'dc:title' },
        { name => 'creator', tag => 'dc:creator' },
        { name => 'subject', tag => 'dc:subject' },
        { name => 'subject_linguisticField', tag => 'dc:subject',
          type => 'olac:linguistic-field', code => 'olac:code' },
        { name => 'description', tag => 'dc:description' },
        { name => 'description_language', tag => 'dc:description',
          type => 'olac:ISO639-3', code => 'olac:code' },
        { name => 'description_language', tag => 'dc:description',
          type => 'olac:language', code => 'olac:code' },
        { name => 'publisher', tag => 'dc:publisher' },
        { name => 'type', tag => 'dc:type', value => 1 },
        { name => 'type_discourseType', tag => 'dc:type',
          type => 'olac:discourse-type', code => 'olac:code' },
        { name => 'type_linguisticType', tag => 'dc:type',
          type => 'olac:linguistic-type', code => 'olac:code' },
        { name => 'identifier', tag => 'dc:identifier' },
        { name => 'source', tag => 'dc:source' },
        # <xs:element name="language" substitutionGroup="dc:language"/>
        # <xs:element name="relation" substitutionGroup="dc:relation"/>
        { name => 'coverage_temporal', tag => 'dc:coverage' },
        { name => 'rights', tag => 'dc:rights' },
        { name => 'title_alternative', tag => 'dcterm:alternative' },
        { name => 'date_created', tag => 'dcterm:created' },
        { name => 'date_issued', tag => 'dcterm:issued' },
        { name => 'date_modified', tag => 'dcterm:modified' },
        { name => 'format_extent', tag => 'dcterm:extent' },
        { name => 'format_medium', tag => 'dcterm:medium' },
        # isVersionOf, hasVersion, isReplacedBy, replaces, isRequiredBy
        # requires, isPartOf, hasPart, isReferencedBy, references
        # isFormatOf, hasFormat, conformsTo
        { name => 'relation', value_type => 'dcterm' },
        { name => 'coverage_spacial', tag => 'dcterm:spatial' },
    ];
}


sub get_record {
    args my $class    => 'ClassName',
         my $resource => { isa => 'Shachi::Model::Resource' };

    my ($doc, $oai) = _create_xml_base('GetRecord');

    my $getrecord = _addChild($doc, $oai, 'GetRecord');
    my $record = _addChild($doc, $getrecord, 'record');
    $record->addChild(_resource_header($doc, $resource));
    $record->addChild(_resource_metadata($doc, $resource));

    return $doc;
}

sub identify {
    args my $class => 'ClassName';

    my ($doc, $oai) = _create_xml_base('Identify');

    my $identify = _addChild($doc, $oai, 'Identify');
    _addChildren($doc, $identify, [
        ['repository', { value => 'SHACHI' }],
        ['baseURL', { value => 'http://shachi.org/olac/oai2' }],
        ['protocolVersion', { value => '2.0' }],
        ['adminEmail', { value => 'mailto:admin@shachi.org' }],
        ['earliestDatestamp', { value => '2000-01-01T00:00:00Z' }],
        ['deletedRecord', { value => 'no' }],
        ['granularity', { value => 'YYYY-MM-DDThh:mm:ssZ' }]
    ]);

    my $desc1 = _addChild($doc, $oai, 'description');
    my $oai_identifier = _addChild($doc, $desc1, 'oai-identifier', { attributes => {
        'xmlns' => 'http://www.openarchives.org/OAI/2.0/oai-identifier',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd',
    } });
    _addChildren($doc, $oai_identifier, [
        ['scheme', { value => 'oai' }],
        ['repositoryIdentifier', { value => 'shachi.org' }],
        ['delemiter', { value => ':' }],
        ['sampleIdentifier', { value => 'oai:shachi.org:N-000001' }]
    ]);

    my $desc2 = _addChild($doc, $oai, 'description');
    my $olac_archive = _addChild($doc, $desc2, 'olac-archive', { attributes => {
        'xmlns' => 'http://www.language-archives.org/OLAC/1.0/olac-archive',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.language-archives.org/OLAC/1.0/olac-archive http://www.language-archives.org/OLAC/1.0/olac-archive.xsd',
        'type' => 'institutional',
    } });
    _addChildren($doc, $olac_archive, [
        ['archiveURL', { value => 'http://shachi.org/' }],
        ['curator', { value => '清貴, 内元 (Uchimoto Kiyotaka); 仁美, 遠山 (Tohyama Hitomi); 俊介, 小澤 (Kozawa Shunsuke); 茂樹, 松原 (Matsubara Shigeki)' }],
        ['curatorEmail', { value => 'mailto:admin@shachi.org' }],
        ['institution', { value => 'The National Institute of Information and Communications Technology (NICT); Nagoya University' }],
        ['institutionURL', { value => 'http://www.nict.go.jp/; http://www.nagoya-u.ac.jp/' }],
        ['shortLocation', { value => 'Kyoto, Japan; Nagoya, Japan' }],
        ['synopsis', { value => 'The purpose of the database is to investigate languages, tag sets, and formats compiled in language resources throughout the world, to systematically store language resource metadata, to create a search function for this information, and to ultimately utilize all this for a more efficient development of language resources.' }],
        ['access', { value => 'Every resource described by the SHACHI metadata repository is a public Web page that may be accessed without restriction.' }]
    ]);

    return $doc;
}

sub list_identifiers {
    args my $class => 'ClassName',
         my $db    => { isa => 'Shachi::Database' },
         my $args  => { isa => 'HashRef', default => {} };

    my ($doc, $oai) = _create_xml_base('ListIdentifiers');

    my $resources = $db->shachi->table('resource')->order_by('id asc')
        ->offset($args->{offset} || 0)->limit($args->{limit} || 200)->list;

    my $list_identifiers = _addChild($doc, $oai, 'ListIdentifiers');
    $list_identifiers->addChild(_resource_header($doc, $_)) for @$resources;

    return $doc;
}

sub list_metadata_formats {
    args my $class => 'ClassName';

    my ($doc, $oai) = _create_xml_base('ListMetadataFormats');

    my $list_metadata_formats = _addChild($doc, $oai, 'ListMetadataFormats');
    my $metadata_format = _addChild($doc, $list_metadata_formats, 'metadataFormat');
    _addChildren($doc, $metadata_format, [
        ['metadataPrefix', { value => 'olac' }],
        ['schema', { value => 'http://www.language-archives.org/OLAC/1.0/olac.xsd' }],
        ['metadataNamespace', { value => 'http://www.language-archives.org/OLAC/1.0/' }],
    ]);

    return $doc;
}

sub list_sets {
    args my $class => 'ClassName';

    my ($doc, $oai) = _create_xml_base('ListSets');
    _addChild($doc, $oai, 'ListSets');

    return $doc;
}

1;