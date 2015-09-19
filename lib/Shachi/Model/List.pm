package Shachi::Model::List;
use strict;
use warnings;
use overload (
    '@{}' => sub { $_[0]->{list} },
    fallback => 1,
);
use Hash::MultiValue;
use List::MoreUtils ();
use List::Util ();
use Carp qw/croak/;
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/list/],
);

# List Manipulating

sub grep {
    my ($self, $pred) = @_;
    $pred //= sub { $_ };
    my $code = ref $pred eq 'CODE' ? $pred : sub { $_->$pred };
    return $self->spawn(
        CORE::grep &$code, @$self
    );
}

sub reverse {
    my $self = shift;
    return $self->spawn(reverse @$self);
}

sub map {
    my ($self, $key) = @_;
    my $code = ref $key eq 'CODE' ? $key : sub { $_->$key };
    return $self->spawn(map &$code, @$self);
}

sub any {
    my ($self, $key) = @_;
    my $code = ref $key eq 'CODE' ? $key : sub { $_->$key };
    return List::MoreUtils::any { &$code } @$self;
}

sub sort_by {
    my ($self, $criteria, $order) = @_;
    $order //= sub { $_[0]->[1] <=> $_[1]->[1] };
    return $self->spawn(
        CORE::map  { $_->[0] }
                CORE::sort { $order->($a, $b) }
                        CORE::map  { [ $_, &$criteria ] }
        @$self
    );
}

sub hash_by {
    my ($self, $key) = @_;
    my $code = ref $key eq 'CODE' ? $key : sub { $_->$key };
    my $hash = Hash::MultiValue->new;
    foreach (@$self) {
        $hash->add($code->($_), $_);
    }
    return $hash;
}

sub uniq_by {
    my ($self, $key) = @_;
    my $code = ref $key eq 'CODE' ? $key : sub { $_->$key };
    my $seen = {};
    return $self->spawn(
        CORE::map  { $_->[0] }
                CORE::grep { not $seen->{ $_->[1] }++ }
                        CORE::map  { [ $_, &$code ] }
        @$self
    );
}

sub spawn {
    my ($self, @list) = @_;
    my $class = ref $self;
    return $class->new(list => [ @list ]);
}

sub to_a { $_[0]->list }

sub size { scalar @{ $_[0]->list } }

sub first {
    my $self = shift;

    if (@_) {
        my $n = shift;
        my $list = $self->list;
        return $self->spawn(
            @{$list}[0 .. ($n > @$list ? @$list : $n)-1]
        );
    } else {
        return $self->list->[0];
    }
}

sub last {
    my $self = shift;

    my $list = $self->list;

    if (@_) {
        my $n = shift;
        return $self->spawn(
            @{$list}[-($n > @$list ? @$list : $n)..-1]
        );
    } else {
        return undef unless @$list;
        return $list->[-1];
    }
}

sub shuffle {
    my $self = shift;
    my @list = $self->deref;
    return $self->spawn(List::Util::shuffle @list);
}

sub push {
    my $self = shift;
    my @list = $self->deref;
    CORE::push @list, @_;
    return $self->spawn(@list);
}

sub deref {
    my $self = shift;
    croak 'Call $list->deref on list context' unless wantarray;
    return @{ $self->list };
}

1;
