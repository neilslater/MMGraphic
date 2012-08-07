use strict;
use warnings;

use Test::More tests => 12;
use Test::NoWarnings;

use File::Spec::Functions;
use FindBin;

use MMGraphic;
use Image::Magick;

my %graphic_of = (
        bg => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'background.png' ) ),
	a => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'a_source_rgba_opaque.png' ) ),
	b => MMGraphic->new( image =>  catfile( $FindBin::Bin, '03_images', 'b_source_rgba_trans.png' ) ),
	c => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'c_source_rgb.jpg' ) ),
	d => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'd_source_rgb.png' ) ),
	e => MMGraphic->new( image =>  catfile( $FindBin::Bin, '03_images', 'e_mask_gs.jpg' ) ),
	f => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'f_mask_gs.png' ) ),
	g => MMGraphic->new( image => catfile( $FindBin::Bin, '03_images', 'g_mask_alpha.png' ) ),
);

##############################################################################
#
# The tests
#

create_graphic(qw(e basic), { flatten => 1} );
create_graphic(qw(e basic0), { theta => 0});
create_graphic(qw(e basic90), { theta => 90, flatten => 1 });
create_graphic(qw(e basic180), { theta => 180});
create_graphic(qw(e basic270), { theta => 270, blur => 10});

create_graphic(qw(e basic270val), { theta => 270, blur => 10, valley_darken => 50, flatten => 1});
create_graphic(qw(e basic270c2), { theta => 270, blur => 5, valley_darken => 50, contrast => 2});
create_graphic(qw(e basic270c10), { theta => 270, blur => 5, valley_darken => 50, contrast => 10});
create_graphic(qw(e basic270c20), { theta => 270, blur => 5, valley_darken => 50, contrast => 20, flatten => 1});
create_graphic(qw(e basic270lm), { theta => 270, blur => 10, valley_darken => 50, mix => 75});
create_graphic(qw(e basic180lmvb), { theta => 180, blur => 5, valley_darken => 70, valley_blur => 10, mix => 90});

exit;

sub create_graphic {
	my ( $emboss_name, $test_name, $options ) = @_;
	$options ||= {};

	# The clone prevents changing loaded graphics on flattening
	my $emboss_graphic = $graphic_of{ $emboss_name }->clone();
	my $result_name = 'mb_' . $emboss_name . '-' . $test_name;
	my $result_graphic = $emboss_graphic->emboss( %$options );

	my $expect_path = catfile( $FindBin::Bin, '03_images', 'expect_' . $test_name .  '.png' );

	my $expect_graphic = MMGraphic->new();
	if (-e $expect_path) {
		$expect_graphic->load_image( $expect_path );
	} else {
		diag( "Auto-passing test $emboss_name, $test_name" );
		$expect_graphic = $result_graphic->clone();
		$expect_graphic->save_image( $expect_path );
	}

	# If we fail the test, write actual result so we can what the problem is, and write difference image too
	my $diff_im = $options->{flatten} ?
		cmp_image( $emboss_graphic->image, $expect_graphic->image, 1, "Emboss (flattened): $emboss_name / $test_name" ) :
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Emboss (result): $emboss_name / $test_name" );
	if ( $diff_im ) {
		$diff_im->Write( catfile( $FindBin::Bin, '03_images', 'diff_' . $result_name . '.png' ) );
		$result_graphic->save_image( catfile( $FindBin::Bin, '03_images', 'result_' . $result_name . '.png' ) );
	}
}

sub cmp_image {
	my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
	my $difference_img = $expect_img->Compare( image => $result_img, metric=>'rmse' );
	return if ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name );
  	return $difference_img;
}
