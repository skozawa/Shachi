package Shachi::Model::Resource;
use strict;
use warnings;
use parent qw/Shachi::Model/;
use Exporter::Lite;

use constant {
    EDIT_STATUS_NEW => 'new',
    EDIT_STATUS_EDITING => 'editing',
    EDIT_STATUS_COMPLETE => 'complete',
    EDIT_STATUS_PENGIND => 'pending',
    EDIT_STATUS_REVISED => 'revised',
    EDIT_STATUS_PROOFED => 'proofed',
};

use constant EDIT_STATUSES => [
    EDIT_STATUS_NEW, EDIT_STATUS_EDITING, EDIT_STATUS_COMPLETE,
    EDIT_STATUS_PENGIND, EDIT_STATUS_REVISED, EDIT_STATUS_PROOFED,
];

our @EXPORT = qw/
    EDIT_STATUS_NEW EDIT_STATUS_EDITING EDIT_STATUS_COMPLETE
    EDIT_STATUS_PENGIND EDIT_STATUS_REVISED EDIT_STATUS_PROOFED
    EDIT_STATUSES
/;

use Class::Accessor::Lite::Lazy (
    new => 1,
    ro  => [qw/id shachi_id status annotator_id edit_status/],
    rw  => [qw/title/],
);

1;
