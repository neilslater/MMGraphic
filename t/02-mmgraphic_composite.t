use strict;
use warnings;

use Test::More tests => 32;
use Test::NoWarnings;

use MMGraphic;
use Image::Magick;

use File::Spec::Functions;
use FindBin;


my %graphic_of = (
    bg => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'background.png' ) ),
	a => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'a_source_rgba_opaque.png' ) ),
	b => MMGraphic->new( image =>  catfile( $FindBin::Bin, '02_images', 'b_source_rgba_trans.png' ) ),
	c => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'c_source_rgb.jpg' ) ),
	d => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'd_source_rgb.png' ) ),
	e => MMGraphic->new( image =>  catfile( $FindBin::Bin, '02_images', 'e_mask_gs.jpg' ) ),
	f => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'f_mask_gs.png' ) ),
	g => MMGraphic->new( image => catfile( $FindBin::Bin, '02_images', 'g_mask_alpha.png' ) ),
);

##############################################################################
#
# The tests
#

create_graphic(1,qw(bg b e basic));
create_graphic(1,qw(bg b f basic));
create_graphic(0,qw(bg b g basic), {}, {use_alpha=>1});

create_graphic(0,qw(bg b e feathered), {}, {feather=>10});
create_graphic(0,qw(bg b f feathered), {}, {feather=>10});
create_graphic(1,qw(bg b g feathered), {}, {feather=>10, use_alpha=>1});

create_graphic(1,qw(bg b e negate), {}, {negate=>1});
create_graphic(1,qw(bg b f negate), {}, {negate=>1});
create_graphic(0,qw(bg b g negate), {}, {negate=>1, use_alpha=>1});

create_graphic(0,qw(bg b e masked_diff), {compose=>'Difference'}, {negate=>1});
create_graphic(0,qw(bg b f masked_diff), {compose=>'Difference'}, {negate=>1});
create_graphic(1,qw(bg b g masked_diff), {compose=>'Difference'}, {negate=>1, use_alpha=>1});

create_graphic(1,qw(bg b e masked_mult), {compose=>'Multiply'}, {negate=>1});
create_graphic(0,qw(bg b f masked_mult), {compose=>'Multiply'}, {negate=>1});
create_graphic(1,qw(bg b g masked_mult), {compose=>'Multiply'}, {negate=>1, use_alpha=>1});

create_graphic(0,qw(bg b none mult), {compose=>'Multiply'}, {});
create_graphic(1,qw(bg b none mult), {compose=>'Multiply'}, {});
create_graphic(1,qw(bg b none mult), {compose=>'Multiply'}, {});

create_graphic(1,qw(bg a e offset), {x=>25,y=>50}, {});
create_graphic(1,qw(bg a f offset), {x=>25,y=>50}, {});
create_graphic(0,qw(bg a g offset), {x=>25,y=>50}, {use_alpha=>1});

create_graphic(0,qw(bg f f self_mask));
create_graphic(1,qw(bg g none alpha));
create_graphic(0,qw(bg f none screen), {compose=>'Screen'});
create_graphic(1,qw(bg g none screen), {compose=>'Screen'});
create_graphic(0,qw(bg f f mask_screen), {compose=>'Screen'});

create_graphic(1,qw(bg b f basic_op70), { opacity => 70 }, {});
create_graphic(1,qw(bg b g feathered_op50), { opacity => 50 }, {feather=>10, use_alpha=>1});
create_graphic(0,qw(bg b f masked_diff_op60), {compose=>'Difference', opacity => 60 }, {negate=>1});
create_graphic(1,qw(bg g none screen_op30), {compose=>'Screen', opacity => 30});
create_graphic(0,qw(bg a none mix_op50), { opacity => 50 }, {});


exit;

sub create_graphic {
	my ( $flatten, $base_name, $overlay_name, $mask_name, $test_name, $options, $mask_options ) = @_;
	$options ||= {};
	$mask_options ||= {};

	my ( $base_graphic, $overlay_graphic, $mask_graphic ) =
		( $graphic_of{ $base_name },$graphic_of{ $overlay_name },$graphic_of{ $mask_name } );
	my $result_name = 'cr_' . $base_name . '-' . $overlay_name . '-' . $mask_name . '-' . $test_name;
	my $result_graphic;

	# Protect against flattening
	$base_graphic = $base_graphic->clone();

	if ( $mask_graphic ) {
		$result_graphic = $base_graphic->composite( flatten => $flatten, graphic => $overlay_graphic, mask => {graphic => $mask_graphic, %$mask_options}, %$options );
	} else {
		$result_graphic = $base_graphic->composite( flatten => $flatten, graphic => $overlay_graphic, %$options );
	}

	my $expect_path = catfile( $FindBin::Bin, '02_images', 'expect_' . $test_name .  '.png' );

	my $expect_graphic = MMGraphic->new();
	if (-e $expect_path) {
		$expect_graphic->load_image( $expect_path );
	} else {
		diag( "Auto-passing test $base_name, $overlay_name, $mask_name, $test_name" );
		$expect_graphic = $result_graphic->clone();
		$expect_graphic->save_image( $expect_path );
	}

	# If we fail the test, write actual result so we can what the problem is, and write difference image too
	my $diff_im = $flatten ?
		cmp_image( $base_graphic->image, $expect_graphic->image, 1, "Composite (flattened): $base_name, $overlay_name, $mask_name / $test_name" ) :
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Composite (result): $base_name, $overlay_name, $mask_name / $test_name" );
	if ( $diff_im ) {
		$diff_im->Write( catfile( $FindBin::Bin, '02_images', 'diff_' . $result_name . '.png' ) );
		$result_graphic->save_image( catfile( $FindBin::Bin, '02_images', 'result_' . $result_name . '.png' ) );
	}
}

sub cmp_image {
	my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
	my $difference_img = $expect_img->Compare( image => $result_img->image, metric=>'rmse' );
	return if ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name );
  	return $difference_img;
}
