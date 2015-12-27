package Shachi::View::Xslate;
use strict;
use warnings;

use Text::Xslate qw(mark_raw);
use HTML::Escape qw(escape_html);
use Shachi::Config;

our $tx = Text::Xslate->new(
    path   => [ Shachi::Config->root->subdir('templates') ],
    cache  => 1,
    syntax => 'TTerse',
    module => [ qw(Text::Xslate::Bridge::TT2Like) ],
    function => {
        format_content => sub {
            my ($content, $args) = @_;
            $args ||= {};
            my @texts;
            foreach my $text ( split /\r?\n/, $content ) {
                $text =~ s!(https?:\/\/[^\s]+)!<a href="$1">$1</a>!g if $args->{linkify};
                push @texts, $text;
            }
            join "<br>\n", @texts;
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
