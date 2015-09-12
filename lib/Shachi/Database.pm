package Shachi::Database;
use strict;
use warnings;

use Module::Load qw/load/;
use DBIx::Handler;

use constant DATABASE_NAMES => qw(shachi);
use Class::Accessor::Lite::Lazy (
    new => 1,
    ro_lazy => [DATABASE_NAMES],
);

sub __connect {
    my $db = shift;
    load $db;
    my $dbconfig = $db->dbconfig;
    my $handler = DBIx::Handler->new(
        $dbconfig->{dsn}, $dbconfig->{user}, $dbconfig->{password}, {
            AutoCommit          => 1,
            PrintError          => 0,
            RaiseError          => 1,
            ShowErrorStatement  => 1,
            AutoInactiveDestroy => 1,
            mysql_enable_utf8   => 1,
        }, {
            on_connect_do     => [
                q(SET NAMES utf8mb4),
                q(SET time_zone = '+00:00')
            ],
        }
    );
    return $db->new(connector => $handler);
}

sub _build_shachi { __connect 'Shachi::DBIx::Lite::Shachi' }

1;
