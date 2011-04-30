#!perl

use strict;
use warnings;

use File::Basename;
use Test::More;
use Test::TestCoverage;

my $dir;

BEGIN {
    $dir = dirname __FILE__;
};

use lib $dir;

my $moose_ok = eval "use Moose" ? 1 : 0;

SKIP: {
    my $class = 'TestCoverage::Foobar';
    test_coverage($class);
    test_coverage_except( $class, qw( BUILD meta ) );
    
    use_ok($class);
    
    my $obj = new_ok( $class => [] );
    
    is( $obj->attr, 'foobar', 'attr is foobar' );
    ok_test_coverage($class);
    
    done_testing();
}
