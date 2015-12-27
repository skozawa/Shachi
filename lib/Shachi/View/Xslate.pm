package Shachi::View::Xslate;
use strict;
use warnings;

use Text::Xslate qw(mark_raw);
use Shachi::Config;
use Shachi::Util qw/format_content/;

our $tx = Text::Xslate->new(
    path   => [ Shachi::Config->root->subdir('templates') ],
    cache  => 1,
    syntax => 'TTerse',
    module => [ qw(Text::Xslate::Bridge::TT2Like) ],
    function => {
        format_content => sub {
            format_content(@_);
        },
    },
);

sub render_file {
    my ($class, $file, $args) = @_;
    my $content = $tx->render($file, $args);
    $content =~ s/^\s+$//mg;
    $content =~ s/>\n+/>\n/g;
    return $content;
}

1;
