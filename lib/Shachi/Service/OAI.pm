package Shachi::Service::OAI;
use strict;
use warnings;
use utf8;
use Smart::Args;
use XML::LibXML;
use DateTime;
use DateTime::Format::W3CDTF;

sub _create_xml_base {
    my ($verb) = @_;

    my $now = DateTime->now;
    my $w3c = DateTime::Format::W3CDTF->new;

    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    my $oai = _addChild($doc, $doc, 'OAI-PMH', { attributes => {
        'xmlns' => 'http://www.openarchives.org/OAI/2.0/',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
    } });
    _addChildren($doc, $oai, [
        ['SCRIPT'],
        ['responseDate', { value => $w3c->format_datetime($now) }],
        ['request', { value => 'http://shachi.org/oai2', attributes => { verb => $verb } } ]
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

sub identify {
    args my $class => 'ClassName';

    my ($doc, $oai) = _create_xml_base('Identify');

    my $identify = _addChild($doc, $oai, 'Identify');
    _addChildren($doc, $identify, [
        ['repository', { value => 'SHACHI' }],
        ['baseURL', { value => 'http://shachi.org/oai2' }],
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


1;
