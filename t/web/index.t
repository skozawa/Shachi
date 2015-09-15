package t::Shachi::Web::Index;
use t::test;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::Index';
}

sub default : Tests {
    my $mech = create_mech;
    $mech->get_ok('/');
}
