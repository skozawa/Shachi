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
