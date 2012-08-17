use strict;
use warnings;

use Test::More tests => 14;
use Test::NoWarnings;

use File::Spec::Functions;
use FindBin;

use MMGraphic;
use Image::Magick;

my $expect_a = Image::Magick->new();
$expect_a->Read( catfile( $FindBin::Bin, '01_images', 'expect_a.png' ) );

my $expect_b = Image::Magick->new();
$expect_b->Read( catfile( $FindBin::Bin, '01_images', 'expect_b.png' ) );

my $bg = MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'background.png' ) );

my %graphic_of = (
    a => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'a_source_rgba_opaque.png' ) ),
    b => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'b_source_rgba_trans.png' ) ),
    c => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'c_source_rgb.jpg' ) ),
    d => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'd_source_rgb.png' ) ),
    e => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'e_mask_gs.jpg' ) ),
    f => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'f_mask_gs.png' ) ),
    g => MMGraphic->new( catfile( $FindBin::Bin, '01_images', 'g_mask_alpha.png' ) ),
);

# Iterate all combinations of source and mask
for my $oname (qw(a b c d)) { for my $mname (qw(e f g)) {
    my $og = $graphic_of{$oname};
    my $mg = $graphic_of{$mname};
    my $im_with_mask = $oname eq 'b' ?
        $og->apply_mask( graphic => $mg, use_alpha => ( $mname eq 'g' ? 1 : 0 ) ) :
        $og->apply_mask( graphic => $mg, use_alpha => ( $mname eq 'g' ? 1 : 0 ) );
    my $result = $bg->composite( graphic => $im_with_mask );

    if ( $oname eq 'b' ) {
        cmp_image( $result->image, $expect_b, 1, "Image result as expected. Combination $oname / $mname" );
    } else {
        cmp_image( $result->image, $expect_a, 1, "Image result as expected. Combination $oname / $mname" );
    }
} }

# Test the "flatten" param
{
    my $oname = 'a'; my $mname = 'f';
    my $og = $graphic_of{$oname};
    my $mg = $graphic_of{$mname};
    $og->apply_mask( graphic => $mg, flatten => 1 );
    my $result = $bg->composite( graphic => $og );
    cmp_image( $result->image, $expect_a, 1, "Image result as expected. Flattened combination $oname / $mname" );
}


exit;

sub cmp_image {
    my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
    my $difference_img = $expect_img->Compare( image => $result_img->image, metric=>'rmse' );
    ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name )
        or diag "Error metric: " . $difference_img->Get('error');
}