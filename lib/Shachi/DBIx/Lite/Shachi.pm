package Shachi::DBIx::Lite::Shachi;
use strict;
use warnings;
use feature 'state';
use parent 'Shachi::DBIx::Lite';
use Module::Load qw/load/;

sub dbname { 'shachi' }

sub schema {
    my $self = shift;
    return state $schema = do {
        my $schema = $self->SUPER::schema(@_);

        for (qw/Annotator Language Metadata Metadata::Value Resource Resource::Metadata/) {
            my $table = join '_', map lc, split /(?:(?=[A-Z])|::)/, $_;
            my $klass = "Shachi::Model::$_";
            load $klass;
            $schema->table($table)->class($klass)->pk(qw/id/);
        }

        $schema;
    };
}

1;
