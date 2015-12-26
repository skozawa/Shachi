package Shachi::Model::Resource;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;
use Shachi::Model::Metadata::Value;

use constant {
    STATUS_PUBLIC => 'public',
    STATUS_LIMITED_BY_LDC => 'limited_by_LDC',
    STATUS_LIMITED_BY_ELRA => 'limited_by_ELRA',
    STATUS_PRIVATE => 'private',

    EDIT_STATUS_NEW => 'new',
    EDIT_STATUS_EDITING => 'editing',
    EDIT_STATUS_COMPLETE => 'complete',
    EDIT_STATUS_PENGIND => 'pending',
    EDIT_STATUS_REVISED => 'revised',
    EDIT_STATUS_PROOFED => 'proofed',
};

use constant STATUSES => [
    STATUS_PUBLIC, STATUS_LIMITED_BY_LDC, STATUS_LIMITED_BY_ELRA, STATUS_PRIVATE
];

use constant EDIT_STATUSES => [
    EDIT_STATUS_NEW, EDIT_STATUS_EDITING, EDIT_STATUS_COMPLETE,
    EDIT_STATUS_PENGIND, EDIT_STATUS_REVISED, EDIT_STATUS_PROOFED,
];

our @EXPORT = qw/
    STATUS_PUBLIC STATUS_LIMITED_BY_LDC STATUS_LIMITED_BY_ELRA STATUS_PRIVATE
    STATUSES

    EDIT_STATUS_NEW EDIT_STATUS_EDITING EDIT_STATUS_COMPLETE
    EDIT_STATUS_PENGIND EDIT_STATUS_REVISED EDIT_STATUS_PROOFED
    EDIT_STATUSES
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id shachi_id status annotator_id edit_status/],
    rw  => [qw/annotator title description metadata_list language_areas/],
);

sub metadata_list_by_name {
    my ($self, $name) = @_;
    return unless $name && $self->metadata_list;
    $self->{_metadata_list_by_name} ||= $self->metadata_list->hash_by('metadata_name');
    my @list = $self->{_metadata_list_by_name}->get_all($name);
    return \@list;
}

sub is_public {
    my $self = shift;
    $self->status eq STATUS_PUBLIC;
}

sub created {
    my $self = shift;
    $self->{_created} ||= $self->_from_db_timestamp($self->{created});
}

sub modified {
    my $self = shift;
    $self->{_modified} ||= $self->_from_db_timestamp($self->{modified});
}

sub is_asia_resource {
    my $self = shift;
    return 0 unless $self->language_areas;
    scalar grep {
        $_ eq LANGUAGE_AREA_ASIA || $_ eq LANGUAGE_AREA_JAPAN
    } @{$self->language_areas};
}

sub link {
    my ($self) = @_;
    '/resources/' . $self->id;
}

sub admin_link {
    my ($self, $lang) = @_;
    '/admin/resources/' . $self->id . ($lang ? "?ln=$lang" : '');
}

1;
