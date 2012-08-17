use strict;
use warnings;

# Test wrapping for MMGraphic::Image

use Test::More tests => 1;
use Test::NoWarnings;

use File::Spec::Functions;
use FindBin;

use MMGraphic::Image;
use Image::Magick;

my $expect_a = Image::Magick->new();
$expect_a->Read( catfile( $FindBin::Bin, '01_images', 'expect_a.png' ) );

my $expect_b = Image::Magick->new();
$expect_b->Read( catfile( $FindBin::Bin, '01_images', 'expect_b.png' ) );

my $mm_im_a = MMGraphic::Image->new();
$mm_im_a->Read( catfile( $FindBin::Bin, '01_images', 'expect_a.png' ) );

my $mm_im_b = $mm_im_a->Clone();

my $mm_im_c = MMGraphic::Image->new( image => catfile( $FindBin::Bin, '01_images', 'expect_a.png' ) );

exit;

sub cmp_image {
    my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
    my $difference_img = $expect_img->Compare( image => $result_img, metric=>'rmse' );
    ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name )
        or diag "Error metric: " . $difference_img->Get('error');
}
