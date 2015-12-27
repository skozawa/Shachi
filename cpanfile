requires 'Plack';
requires 'parent';
requires 'Exporter::Lite';
requires 'Config::ENV';

requires 'Class::Accessor::Lite';
requires 'Class::Accessor::Lite::Lazy';
requires 'Module::Load';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'List::UtilsBy';
requires 'JSON::XS';
requires 'JSON::Types';
requires 'Path::Class';
requires 'Try::Tiny';
requires 'Hash::MultiValue';
requires 'Smart::Args';
requires 'Carp';
requires 'Search::Query';
requires 'HTML::Escape';

# route
requires 'Router::Simple';

# server
requires 'Plack';
requires 'Starlet';
requires 'Plack::Middleware::ServerStatus::Lite';
requires 'HTTP::Throwable';

# view
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';

# db
requires 'SQL::Maker';
requires 'DBD::mysql';
requires 'DBIx::Handler';
requires 'DBIx::Lite';
requires 'DBIx::Lite::Row';
requires 'SQL::Abstract::Plugin::InsertMulti';
requires 'DateTime::Format::MySQL';

on develop => sub {
    requires 'Proclet';

    requires 'Devel::KYTProf';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Class';
    requires 'Test::Deep';
    requires 'Test::Fatal';
    requires 'Test::Mock::Guard';
    requires 'Test::WWW::Stub';
    requires 'Test::Time';
    requires 'Test::WWW::Mechanize::PSGI';
    requires 'String::Random';
};
