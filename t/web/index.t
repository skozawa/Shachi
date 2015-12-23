package t::Shachi::Web::Index;
use t::test;

sub _require : Test(startup => 1) {
    use_ok 'Shachi::Web::Index';
}

sub default : Tests {
    my $mech = create_mech;
    $mech->get_ok('/');
}

sub default_asia : Tests {
    my $mech = create_mech;
    $mech->get_ok('/asia/');
}

sub about : Tests {
    my $mech = create_mech;
    $mech->get_ok('/about');
}

sub about_asia : Tests {
    my $mech = create_mech;
    $mech->get_ok('/asia/about');
}

sub publications : Tests {
    my $mech = create_mech;
    $mech->get_ok('/publications');
}

sub publications_asia : Tests {
    my $mech = create_mech;
    $mech->get_ok('/asia/publications');
}

sub news : Tests {
    my $mech = create_mech;
    $mech->get_ok('/news');
}

sub news_asia : Tests {
    my $mech = create_mech;
    $mech->get_ok('/asia/news');
}

sub contact : Tests {
    my $mech = create_mech;
    $mech->get_ok('/contact');
}

sub contact_asia : Tests {
    my $mech = create_mech;
    $mech->get_ok('/asia/contact');
}
