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
    my $doc = Shachi::Service::OAI->identify;
    return $c->xml($doc->toString);
}

sub _validate_verb {
    my ($class, $verb) = @_;
    return unless $verb;
    return any { $verb eq $_ }
        qw/GetRecord Identify ListIdentifiers ListMetadataFormats ListRecords ListSets/;
}

1;
