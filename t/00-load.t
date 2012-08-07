#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MMGraphic' ) || print "Bail out!\n";
}

diag( "Testing MMGraphic $MMGraphic::VERSION, Perl $], $^X" );
