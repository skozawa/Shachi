package Shachi::Config;
use strict;
use warnings;

use Config::ENV 'SHACHI_ENV', export => 'config';
use Path::Class qw(file);
use Shachi::Config::Router;

my $Root = file(__FILE__)->dir->parent->parent->absolute;
my $Rooter = Shachi::Config::Router->router;

sub root { $Root }
sub router { $Rooter }
sub dbinfo {
    my $data = root->subdir('config')->file('db.' . $ENV{PLACK_ENV})->slurp;
    my $config = {};
    foreach my $line ( split /\r?\n/, $data ) {
        next unless $line;
        my ($name, $user, $pass, $dsn) = split /,/, $line;
        $config->{$name} = { user => $user, password => $pass, dsn => $dsn };
    }
    $config;
}

common {
    'db' => dbinfo(),

    'static.root' => 'static',
};

1;
