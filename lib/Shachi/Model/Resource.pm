package Shachi::Model::Resource;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

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
    rw  => [qw/title metadata_list/],
);

sub metadata {
    my ($self, $metadata) = @_;
    return unless $metadata && $self->metadata_list;
    $self->{_metadata_by_id} ||= $self->metadata_list->hash_by('metadata_id');
    my @list = $self->{_metadata_by_id}->get_all($metadata->id);
    return \@list;
}

sub created {
    my $self = shift;
    $self->{_created} ||= $self->_from_db_timestamp($self->{created});
}

sub modified {
    my $self = shift;
    $self->{_modified} ||= $self->_from_db_timestamp($self->{modified});
}

sub status_label {
    my $self = shift;
    return 'private'       if $self->status eq STATUS_PRIVATE;
    return 'limited(ELRA)' if $self->status eq STATUS_LIMITED_BY_ELRA;
    return 'limited(LDC)'  if $self->status eq STATUS_LIMITED_BY_LDC;
    return 'public';
}

sub admin_link {
    my $self = shift;
    '/admin/resources/' . $self->id;
}

1;
