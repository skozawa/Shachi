package Shachi::DBIx::Lite;
use strict;
use warnings;
use parent 'DBIx::Lite';
use DBIx::Handler;
use Module::Load qw/load/;
use SQL::Abstract::Plugin::InsertMulti;
use Carp qw/croak/;
use DateTime;
use DateTime::Format::MySQL;

use Shachi::Config ();

sub config { 'Shachi::Config' }

sub dbname { die }

sub dbconfig {
    $_[0]->config->param('db')->{$_[0]->dbname};
}

sub time_zone { 'Asia/Tokyo' }

sub now {
    my $self = shift;
    return DateTime->now(
        time_zone => $self->time_zone,
        formatter => 'DateTime::Format::MySQL',
    );
}

# my $lit = $rs->list;
sub DBIx::Lite::ResultSet::list {
    my ($self, $what) = @_;
    $what //= 'all'; # or 'single'
    return $self->mk_list($self->$what);
}

sub DBIx::Lite::ResultSet::mk_list {
    my ($self, @list) = @_;
    my $list_class = $self->list_class;
    return $list_class->new(
        list => [ @list ],
    );
}

sub DBIx::Lite::ResultSet::list_class {
    my $self = shift;
    my $class_name = $self->{table}->{class};
    $class_name =~ s/::Model::/::Model::List::/ if $class_name;
    my $list_class = $class_name || 'Shachi::Model::List';
    unless (eval { load $list_class; 1 }) {
        load $list_class = 'Shachi::Model::List';
    }
    return $list_class;
}

# DBIx::Lite::ResultSet::insertを参考にinsert_multi用メソッドを追加
sub DBIx::Lite::ResultSet::insert_multi_sql {
    my $self = shift;
    my $insert_rows = shift;
    my $opts = shift;
    ref $insert_rows eq 'ARRAY' or croak "insert_multi_sql() requires a arrayref";

    return $self->{dbix_lite}->{abstract}->insert_multi(
        $self->{table}{name}, $insert_rows, $opts
    );
}

sub DBIx::Lite::ResultSet::insert_multi_sth {
    my $self = shift;
    my $insert_rows = shift;
    my $opts = shift;
    ref $insert_rows eq 'ARRAY' or croak "insert_multi_sth() requires a arrayref";

    my ($sql, @bind) = $self->insert_multi_sql($insert_rows, $opts);
    return $self->{dbix_lite}->dbh->prepare($sql) || undef, @bind;
}

sub DBIx::Lite::ResultSet::insert_multi {
    my $self = shift;
    my $insert_rows = shift;
    my $opts = shift;
    ref $insert_rows eq 'ARRAY' or croak "insert_multi() requires a arrayref";

    my $res;
    $self->{dbix_lite}->dbh_do(sub {
        my ($sth, @bind) = $self->insert_multi_sth($insert_rows, $opts);
        $res = $sth->execute(@bind);
    });
    return undef if !$res;

    if (my $pk = $self->{table}->autopk) {
        for my $cols ( @$insert_rows ) {
            $cols = clone $cols;
            $cols->{$pk} = $self->{dbix_lite}->_autopk($self->{table}{name})
                if !exists $cols->{$pk};
        }
    }
    return [ map { $self->_inflate_row($_) } @$insert_rows ];
}

1;
