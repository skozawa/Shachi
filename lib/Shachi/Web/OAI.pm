package Shachi::Web::OAI;
use strict;
use warnings;
use List::MoreUtils qw/any/;
use Shachi::Service::OAI;
use Shachi::Service::Resource;

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
        $allow_map->{$_} ? () : ($_ => $params->{$_})
    } keys %$params };
}

sub _validate_identifier {
    my ($class, $identifier) = @_;
    if ( $identifier =~ m!^oai:shachi\.org:([NCDGTO]-\d{6})$! ) {
        return $1;
    }
    return 0;
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
        )->toString) unless $shachi_id && $resource;
    }

    my $doc = Shachi::Service::OAI->list_metadata_formats;
    return $c->xml($doc->toString);
}


1;
