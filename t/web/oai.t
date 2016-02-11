package t::Shachi::Web::OAI;
use t::test;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::OAI';
}

sub oai2 : Tests {
    subtest 'badverb' => sub {
        my $mech = create_mech;
        $mech->get("/olac/oai2?verb=aaa");
        my $doc = $mech->xml_doc;
        ok $doc;
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badVerb';
    };

    subtest 'normal request' => sub {
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=Identify');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('error');
    };
}

sub _validate_verb : Tests {
    for my $verb (qw/GetRecord Identify ListIdentifiers ListMetadataFormats ListRecords ListSets/) {
        ok Shachi::Web::OAI->_validate_verb($verb);
    }
    ok ! Shachi::Web::OAI->_validate_verb('aaaa');
}

sub _invalid_required_arguments : Tests {
    is_deeply Shachi::Web::OAI->_invalid_required_arguments(
        { verb => 'Identify' }, [qw/verb/],
    ), [];

    is_deeply Shachi::Web::OAI->_invalid_required_arguments(
        { verb => 'RetRecord', metadataPrefix => 'olac' }, [qw/verb metadataPrefix identifier/],
    ), [qw/identifier/];
}

sub _invalid_arguments : Tests {
    is_deeply Shachi::Web::OAI->_invalid_arguments(
        { verb => 'Identify' }, [qw/verb/],
    ), {};

    is_deeply Shachi::Web::OAI->_invalid_arguments(
        { verb => 'Identify', metadataPrefix => 'olac' }, [qw/verb/],
    ), { metadataPrefix => 'olac' };
}

sub identify : Tests {
    subtest 'normal' => sub {
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=Identify');
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('Identify');
    };

    subtest 'bad argument' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=Identify&metadataPrefix=olac');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('Identify');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };
}
