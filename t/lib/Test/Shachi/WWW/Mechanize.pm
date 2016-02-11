package Test::Shachi::WWW::Mechanize;
use strict;
use warnings;
use parent qw/Test::WWW::Mechanize::PSGI/;
use Test::More ();
use XML::LibXML;
use Shachi::Web;


BEGIN {
    $ENV{PLACK_ENV} = 'test';
}

sub new {
    my ($class, %args) = @_;

    my $self;
    my $app = sub {
        my $env = shift;
        $self->{env} = $env;
        my $res = Shachi::Web->run($env);
        $res;
    };

    $self = $class->SUPER::new(
        onerror => \&Test::More::diag,
        onwarn  => \&Test::More::diag,
        app     => $app,
        %args,
    );

    return $self;
}

sub xml_doc {
    my $self = shift;
    my $content = $self->response->content;
    my $doc;
    eval { $doc = XML::LibXML->load_xml(string => $content); };
    return $doc;
}

1;
