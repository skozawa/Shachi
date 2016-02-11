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

sub _validate_identifier : Tests {
    ok Shachi::Web::OAI->_validate_identifier('oai:shachi.org:N-000011');
    ok ! Shachi::Web::OAI->_validate_identifier('oai:shachi:N-000012');
    ok ! Shachi::Web::OAI->_validate_identifier('N-000001');
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

sub getrecord : Tests {
    truncate_db_with_setup;

    subtest 'normal request' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=GetRecord&metadataPrefix=olac&identifier=' . $resource->oai_identifier);
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('GetRecord');
    };

    subtest 'invalid argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=GetRecord&metadataPrefix=olac&from=2&identifier=' . $resource->oai_identifier);
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('GetRecord');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'lack required argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=GetRecord&identifier=' . $resource->oai_identifier);
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('GetRecord');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'invalid metadataPrefix' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=GetRecord&metadataPrefix=oc&identifier=' . $resource->oai_identifier);
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('GetRecord');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'cannotDisseminateFormat';
    };

    subtest 'no resource' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=GetRecord&metadataPrefix=olac&identifier=N-0001');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('GetRecord');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'idDoesNotExist';
    };
}

sub listidentifiers : Tests {
    subtest 'normal request' => sub {
        create_resource;
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListIdentifiers&metadataPrefix=olac');
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('ListIdentifiers');
    };

    subtest 'invalid argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListIdentifiers&metadataPrefix=olac&identifier=AA');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListIdentifiers');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'lack required argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListIdentifiers');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListIdentifiers');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'invalid argument: resumptionToken' => sub {
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListIdentifiers&metadataPrefix=olac&resumptionToken=aaa');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListIdentifiers');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'invalid metadataPrefix' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListIdentifiers&metadataPrefix=oc');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListIdentifiers');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'cannotDisseminateFormat';
    };

    subtest 'set is invalid' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListIdentifiers&metadataPrefix=olac&set=aa:bb');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListIdentifiers');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'noSetHierarchy';
    };
}

sub listmetadataformats : Tests {
    subtest 'normal request' => sub {
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListMetadataFormats');
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('ListMetadataFormats');
    };

    subtest 'with identifier' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListMetadataFormats&identifier=' . $resource->oai_identifier);
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('ListMetadataFormats');
    };

    subtest 'invalid identifier' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListMetadataFormats&identifier=N-000001');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListMetadataFormats');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'idDoesNotExist';
    };

    subtest 'not found resource' => sub {
        my $resource = create_resource;
        my $identifier = $resource->oai_identifier;
        $identifier =~ s/:N-/:S-/;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListMetadataFormats&identifier=' . $identifier);
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListMetadataFormats');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'idDoesNotExist';
    };

    subtest 'bad argument' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListMetadataFormats&metadataPrefix=olac');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListMetadataFormats');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };
}

sub listrecords : Tests {
    subtest 'normal request' => sub {
        create_resource;
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListRecords&metadataPrefix=olac');
        my $doc = $mech->xml_doc;
        ok $doc->getElementsByTagName('ListRecords');
    };

    subtest 'invalid argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListRecords&metadataPrefix=olac&identifier=AA');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListRecords');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'lack required argument' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListRecords');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListRecords');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'invalid argument: resumptionToken' => sub {
        my $mech = create_mech;
        $mech->get_ok('/olac/oai2?verb=ListRecords&metadataPrefix=olac&resumptionToken=aaa');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListRecords');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'badArgument';
    };

    subtest 'invalid metadataPrefix' => sub {
        my $resource = create_resource;
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListRecords&metadataPrefix=oc');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListRecords');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'cannotDisseminateFormat';
    };

    subtest 'set is invalid' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListRecords&metadataPrefix=olac&set=aa:bb');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListRecords');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'noSetHierarchy';
    };
}

sub listsets : Tests {
    subtest 'normal request' => sub {
        my $mech = create_mech;
        $mech->get('/olac/oai2?verb=ListSets');
        my $doc = $mech->xml_doc;
        ok ! $doc->getElementsByTagName('ListSets');
        my $error = $doc->getElementsByTagName('error')->[0];
        ok $error;
        is $error->getAttribute('code'), 'noSetHierarchy';
    };
}
