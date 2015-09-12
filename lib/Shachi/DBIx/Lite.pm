package Shachi::DBIx::Lite;
use strict;
use warnings;
use parent 'DBIx::Lite';
use DBIx::Handler;

use Shachi::Config ();

sub config { 'Shachi::Config' }

sub dbname { die }

sub dbconfig {
    $_[0]->config->param('db')->{$_[0]->dbname};
}

1;
