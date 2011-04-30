#!perl -T

use strict;
use warnings;
use Test::More;

eval "use Test::CheckManifest 1.24";
plan skip_all => "Test::CheckManifest 1.24 required" if $@;
ok_manifest({filter => [qr/\.(?:svn|git)/]});
