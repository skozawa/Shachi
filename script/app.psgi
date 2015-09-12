#!/usr/bin/env plackup
use strict;
use warnings;

use lib 'lib';

require Shachi::Web;
Shachi::Web->as_psgi;
