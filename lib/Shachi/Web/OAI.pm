package Shachi::Web::OAI;
use strict;
use warnings;
use List::MoreUtils qw/any/;
use Shachi::Service::OAI;
use Shachi::Service::Resource;
use DateTime;
use DateTime::Format::W3CDTF;
use Data::MessagePack;
use MIME::Base64;

my $w3c = DateTime::Format::W3CDTF->new;

sub default {
    my ($class, $c) = @_;
    return $c->html_locale('olac.html');
}

sub oai2 {
    my ($class, $c) = @_;
    my $verb = $c->req->param('verb') || '';
    unless ( $class->_validate_verb($verb) ) {
        return $c->xml(Shachi::Service::OAI->bad_verb(verb => $verb)->toString);
    }
    my $method = lc $verb;
    $class->$method($c);
}

sub _validate_verb {
    my ($class, $verb) = @_;
    return unless $verb;
    return any { $verb eq $_ }
        qw/GetRecord Identify ListIdentifiers ListMetadataFormats ListRecords ListSets/;
}

sub _validate_arguments {
    my ($class, $params, $required, $optional) = @_;
    return (
        $class->_invalid_required_arguments($params, $required),
        $class->_invalid_arguments($params, [ @$required, @$optional ]),
    );
}

sub _invalid_required_arguments {
    my ($class, $params, $required) = @_;
    return [ grep { !$params->{$_} } @$required ];
}

sub _invalid_arguments {
    my ($class, $params, $allow) = @_;
    my $allow_map = +{ map { $_ => 1 } @$allow };
    return +{ map {
        my $is_valid = ($allow_map->{$_} && ($_ eq 'from' || $_ eq 'until')) ?
            $class->_validate_datetime($params->{$_}) : $allow_map->{$_};
        $is_valid ? () : ($_ => $params->{$_})
    } keys %$params };
}

sub _validate_datetime {
    my ($class, $datetime) = @_;
    return unless $datetime;
    eval { $w3c->parse_datetime($datetime) };
}

sub _validate_identifier {
    my ($class, $identifier) = @_;
    if ( $identifier =~ m!^oai:shachi\.org:([NCDGTO]-\d{6})$! ) {
        return $1;
    }
    return 0;
}

sub _validate_metadata_prefix {
    my ($class, $metadata_prefix) = @_;
    return $metadata_prefix eq 'olac';
}

sub encode_resumption_token {
    my ($class, $args) = @_;
    my $hash = {
        m => $args->{metadataPrefix} || '',
        f => $args->{from} ? $args->{from}->epoch : 0,
        u => $args->{until} ? $args->{until}->epoch : 0,
        o => $args->{offset} || 0,
        e => time + 60 * 60 * 30,
    };
    encode_base64(Data::MessagePack->pack($hash));
}

sub decode_resumption_token {
    my ($class, $token) = @_;
    eval { Data::MessagePack->unpack(decode_base64($token)) };
}

sub _validate_resumption_token {
    my ($class, $token) = @_;
    my $hash = $class->decode_resumption_token($token) or return;
    return unless $hash->{e};
    return if $hash->{e} < time;
    return 1;
}

sub create_args_from_params {
    my ($class, $params) = @_;
    my $args = $params->{resumptionToken} ?
        $class->decode_resumption_token($params->{resumptionToken}) : {};
    return +{
        metadataPrefix => $args->{m} || $params->{metadataPrefix},
        from           => $args->{f} ? DateTime->from_epoch(epoch => $args->{f}) :
            $class->_validate_datetime($params->{from}) || 0,
        until          => $args->{u} ? DateTime->from_epoch(epoch => $args->{u}) :
            $class->_validate_datetime($params->{until}) || DateTime->now,
        offset         => $args->{o} || 0,
    };
}

# required: identifier, metadataPrefix
# error: badArgument, cannotDisseminateFormat idDoesNotExist
sub getrecord {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    my ($required, $invalid) = $class->_validate_arguments(
        $params, [qw/verb identifier metadataPrefix/], []
    );
    return $c->xml(Shachi::Service::OAI->bad_argument(
        required => $required, invalid => $invalid,
    )->toString) if @$required || %$invalid;

    unless ( $class->_validate_metadata_prefix($params->{metadataPrefix}) ) {
        return $c->xml(Shachi::Service::OAI->cannot_disseminate_format(
            verb => $params->{verb}, metadata_prefix => $params->{metadataPrefix},
            opts => { identifier => $params->{identifier} }
        )->toString);
    }

    my $shachi_id = $class->_validate_identifier($params->{identifier});
    my $resource = $shachi_id ? Shachi::Service::Resource->find_by_shachi_id(
        db => $c->db, shachi_id => $shachi_id
    ) : undef;
    return $c->xml(Shachi::Service::OAI->id_does_not_exist(
        verb => $params->{verb}, identifier => $params->{identifier},
        opts => { metadataPrefix => $params->{metadataPrefix} },
    )->toString) unless $resource;

    Shachi::Service::Resource->embed_resource_metadata_list(
        db => $c->db, resources => $resource->as_list, language => $c->english,
    );
    my $doc = Shachi::Service::OAI->get_record(resource => $resource);
    return $c->xml($doc->toString);
}

# error: badArgument
sub identify {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    my ($required, $invalid) = $class->_validate_arguments($params, [qw/verb/], []);
    if ( @$required || %$invalid ) {
        return $c->xml(Shachi::Service::OAI->bad_argument(
            required => $required, invalid => $invalid,
        )->toString);
    }

    my $doc = Shachi::Service::OAI->identify;
    return $c->xml($doc->toString);
}

# required: metadataPrefix
# optional: from, until, set
# exclusive: resumptionToken
# error: badArgument, badResumptionToken, cannotDisseminateFormat, noRecordsMatch, noSetHierarchy
sub listidentifiers {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    if ( my $token = $params->{resumptionToken} ) {
        # verb, resumptionToken 以外のArgumentがある
        return $c->xml(
            Shachi::Service::OAI->bad_argument(required => [], invalid => {})->toString
        ) if scalar keys %$params > 2;

        return $c->xml(
            Shachi::Service::OAI->bad_resumption_token(
                token => $token, opts => { verb => $params->{verb} },
            )
        ) unless $class->_validate_resumption_token($token);
    } else {
        my ($required, $invalid) = $class->_validate_arguments($params, [qw/verb metadataPrefix/], [qw/from until set/]);
        return $c->xml(Shachi::Service::OAI->bad_argument(
            required => $required, invalid => $invalid,
        )->toString) if @$required || %$invalid;

        unless ( $class->_validate_metadata_prefix($params->{metadataPrefix}) ) {
            return $c->xml(Shachi::Service::OAI->cannot_disseminate_format(
                verb => $params->{verb}, metadata_prefix => $params->{metadataPrefix},
                opts => { identifier => $params->{identifier} }
            )->toString);
        }

        return $c->xml(
            Shachi::Service::OAI->no_set_hierarchy(verb => $params->{verb})->toString
            ) if $params->{set};
    }

    my $limit = 200;
    my $args = $class->create_args_from_params($params);
    my $offset = $args->{offset} || 0;
    my $conditions = $args->{from} || $args->{until} ? {
        modified => {
            $args->{from}  ? ('>=' => $args->{from})  : (),
            $args->{until} ? ('<'  => $args->{until}) : (),
        },
    } : {};

    my $resources = $c->db->shachi->table('resource')->search($conditions)
        ->order_by('id asc')->offset($offset)->limit($limit)->list;

    return $c->xml(Shachi::Service::OAI->no_records_match(
        verb => $params->{verb},
    )->toString) if $resources->size == 0;

    $args->{offset} += $limit;
    my $token = $resources->size == $limit ? $class->encode_resumption_token($args) : '';
    $c->xml( Shachi::Service::OAI->list_identifiers(
        resources => $resources,
        metadata_prefix => $args->{metadataPrefix},
        resumptionToken => $token,
    )->toString );
}

# optional: identifier
# error: badArgument, idDoesNotExist, noMetadataFormats
sub listmetadataformats {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    my ($required, $invalid) = $class->_validate_arguments($params, [qw/verb/], [qw/identifier/]);
    return $c->xml(Shachi::Service::OAI->bad_argument(
        required => $required, invalid => $invalid,
    )->toString) if @$required || %$invalid;

    if ( $params->{identifier} ) {
        my $shachi_id = $class->_validate_identifier($params->{identifier});
        my $resource = $shachi_id ?
            Shachi::Service::Resource->find_by_shachi_id(
                db => $c->db, shachi_id => $shachi_id,
            ) : undef;
        return $c->xml(Shachi::Service::OAI->id_does_not_exist(
            verb => $params->{verb}, identifier => $params->{identifier}
        )->toString) unless $resource;
    }

    my $doc = Shachi::Service::OAI->list_metadata_formats;
    return $c->xml($doc->toString);
}

# required: metadataPrefix
# optional: from, until, set
# exclusive: resumptionToken
# error: badArgument, badResumptionToken, cannotDisseminateFormat, noRecordsMatch, noSetHierarchy
sub listrecords {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    if ( my $token = $params->{resumptionToken} ) {
        # verb, resumptionToken 以外のArgumentがある
        return $c->xml(
            Shachi::Service::OAI->bad_argument(required => [], invalid => {})->toString
        ) if scalar keys %$params > 2;

        return $c->xml(
            Shachi::Service::OAI->bad_resumption_token(
                token => $token, opts => { verb => $params->{verb} },
            )
        ) unless $class->_validate_resumption_token($token);
    } else {
        my ($required, $invalid) = $class->_validate_arguments($params, [qw/verb metadataPrefix/], [qw/from until set/]);
        return $c->xml(Shachi::Service::OAI->bad_argument(
            required => $required, invalid => $invalid,
        )->toString) if @$required || %$invalid;

        unless ( $class->_validate_metadata_prefix($params->{metadataPrefix}) ) {
            return $c->xml(Shachi::Service::OAI->cannot_disseminate_format(
                verb => $params->{verb}, metadata_prefix => $params->{metadataPrefix},
                opts => { identifier => $params->{identifier} }
            )->toString);
        }

        return $c->xml(
            Shachi::Service::OAI->no_set_hierarchy(verb => $params->{verb})->toString
            ) if $params->{set};
    }

    my $limit = 200;
    my $args = $class->create_args_from_params($params);
    my $offset = $args->{offset} || 0;
    my $conditions = $args->{from} || $args->{until} ? {
        modified => {
            $args->{from}  ? ('>=' => $args->{from})  : (),
            $args->{until} ? ('<'  => $args->{until}) : (),
        },
    } : {};

    my $resources = $c->db->shachi->table('resource')->search($conditions)
        ->order_by('id asc')->offset($offset)->limit($limit)->list;

    return $c->xml(Shachi::Service::OAI->no_records_match(
        verb => $params->{verb},
    )->toString) if $resources->size == 0;

    Shachi::Service::Resource->embed_resource_metadata_list(
        db => $c->db, resources => $resources, language => $c->english,
    );

    $args->{offset} += $limit;
    my $token = $resources->size == $limit ? $class->encode_resumption_token($args) : '';
    $c->xml( Shachi::Service::OAI->list_records(
        resources => $resources,
        metadata_prefix => $args->{metadataPrefix},
        resumptionToken => $token,
    )->toString );
}

# exclusive: resumptionToken
# error: badArgument, badResumptionToken, noSetHierarchy
sub listsets {
    my ($class, $c) = @_;
    my $params = $c->req->parameters->as_hashref;

    # SHACHIでは非対応
    return $c->xml(Shachi::Service::OAI->no_set_hierarchy(verb => $params->{verb})->toString);
}

1;
