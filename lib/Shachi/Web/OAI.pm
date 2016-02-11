package Shachi::Web::OAI;
use strict;
use warnings;
use List::MoreUtils qw/any/;
use Shachi::Service::OAI;

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


1;
