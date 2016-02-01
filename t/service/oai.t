package t::Shachi::Service::OAI;
use t::test;
use utf8;
use Shachi::Database;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Service::OAI';
}

sub identify : Tests {
    my $doc = Shachi::Service::OAI->identify;

    ok $doc->getElementsByTagName('SCRIPT');
    ok $doc->getElementsByTagName('responseDate');
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/oai2';

    ok $doc->getElementsByTagName('Identify');
    for ( (
        ['repository', 'SHACHI'],
        ['baseURL', 'http://shachi.org/oai2'],
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

sub list_metadata_formats : Tests {
    my $doc = Shachi::Service::OAI->list_metadata_formats;

    ok $doc->getElementsByTagName('SCRIPT');
    ok $doc->getElementsByTagName('responseDate');
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/oai2';

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
    is $doc->getElementsByTagName('request')->[0]->textContent, 'http://shachi.org/oai2';

    ok $doc->getElementsByTagName('ListSets');
}
