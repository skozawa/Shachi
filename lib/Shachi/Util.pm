package Shachi::Util;
use strict;
use warnings;
use utf8;
use Exporter::Lite;
use HTML::Escape qw/escape_html/;

our @EXPORT_OK = qw/
    format_content
/;

sub format_content {
    my ($content, $args) = @_;
    return $content unless $content;
    $args ||= {};
    my @texts;
    foreach my $text ( split /\r?\n/, $content ) {
        $text =~ s!(https?:\/\/[^\s]+)!<a href="$1">$1</a>!g if $args->{linkify};
        push @texts, $text;
    }
    join "<br>\n", @texts;
}

1;
