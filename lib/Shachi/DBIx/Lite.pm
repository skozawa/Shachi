package Shachi::DBIx::Lite;
use strict;
use warnings;
use parent 'DBIx::Lite';
use DBIx::Handler;
use Module::Load qw/load/;

use Shachi::Config ();

sub config { 'Shachi::Config' }

sub dbname { die }

sub dbconfig {
    $_[0]->config->param('db')->{$_[0]->dbname};
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

1;
