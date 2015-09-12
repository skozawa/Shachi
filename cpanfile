requires 'Plack';
requires 'parent';
requires 'Exporter::Lite';
requires 'Config::ENV';

requires 'Class::Accessor::Lite';
requires 'Class::Accessor::Lite::Lazy';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'List::UtilsBy';
requires 'JSON::Types';
requires 'Path::Class';
requires 'Try::Tiny';
requires 'Module::Load';

# http
requires 'Router::Simple';
requires 'HTTP::Response::Maker::PSGI';
requires 'HTTP::Response::Maker::Plack';

# server
requires 'Plack';
requires 'Starlet';
requires 'Plack::Middleware::ServerStatus::Lite';
requires 'HTTP::Throwable';
