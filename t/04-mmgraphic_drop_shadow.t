use strict;
use warnings;

use Test::More tests => 24;
use Test::NoWarnings;

use File::Spec::Functions;
use FindBin;

use MMGraphic;
use Image::Magick;

my %graphic_of = (
        bg => MMGraphic->new( image => catfile( $FindBin::Bin, '04_images', 'background.jpg' ) ),
	fs => MMGraphic->new( image => catfile( $FindBin::Bin, '04_images', 'fancy_shadow.png' ) ),
	a => MMGraphic->new( image =>  catfile( $FindBin::Bin, '04_images', 'a_object.png' ) ),
	b => MMGraphic->new( image =>  catfile( $FindBin::Bin, '04_images', 'b_object.png' ) ),
);

##############################################################################
#
# The tests
#

create_graphic(qw(a basic), { flatten => 1 });

create_graphic(qw(a blur30), { blur => 30 });

create_graphic(qw(a blur30e), { enlarge => 20, blur => 15 });

create_graphic(qw(a no_enlarge), { enlarge => 0, blur => 15 });

create_graphic(qw(a sharp), { enlarge => 12, blur => 0, opacity => 80 });

create_graphic(qw(a faint_sharp), { enlarge => 15, blur => 2, opacity => 50 });

create_graphic(qw(a custom_shadow), { blur => 30, shadow_graphic => $graphic_of{fs}, flatten => 1  });

create_graphic(qw(a red20), { blur => 20, shadow_colour => 'red', flatten => 1  });

create_graphic(qw(a red20), { blur => 20, shadow_colour => 'red' });

create_graphic(qw(a green10), { blur => 10, enlarge => 10, shadow_colour => 'green', opacity => 90 });


create_graphic(qw(b basic_b), {  });

create_graphic(qw(b blur30_b), { blur => 30 });

create_graphic(qw(b blur30e_b), { enlarge => 20, blur => 15, flatten => 1 });

create_graphic(qw(b no_enlarge_b), { enlarge => 0, blur => 15 });

create_graphic(qw(b sharp_b), { enlarge => 12, blur => 0, opacity => 80 });

create_graphic(qw(b faint_sharp_b), { enlarge => 15, blur => 2, opacity => 50 });

create_graphic(qw(b custom_shadow_b), { blur => 30, shadow_graphic => $graphic_of{fs} });

create_graphic(qw(b red20_b), { blur => 20, shadow_colour => 'red' });

create_graphic(qw(b green10_b), { blur => 10, enlarge => 10, shadow_colour => 'green', opacity => 90, flatten => 1 });

create_graphic(qw(b blue10_so), { enlarge => 3, shadow_colour => 'cyan', opacity => 75, shadow_only => 1 });

create_graphic(qw(b blue10_so), { enlarge => 3, shadow_colour => 'cyan', opacity => 75, shadow_only => 1, flatten => 1 });

create_graphic(qw(b offset1), { offset_x=>3, offset_y=>5, flatten => 1 });

create_graphic(qw(b offset2), { offset_x=>4, offset_y=>-5,  shadow_graphic => $graphic_of{fs} });

exit;

sub create_graphic {
	my ( $shadow_name, $test_name, $options ) = @_;
	$options ||= {};

	# The clone prevents changing loaded graphics on flattening
	my $shadow_graphic = $graphic_of{ $shadow_name }->clone();
	my $result_name = 'mb_' . $shadow_name . '-' . $test_name;
	my $interim_graphic = $shadow_graphic->drop_shadow( %$options );

	my $result_graphic = $options->{flatten} ?
		$graphic_of{bg}->composite( graphic => $shadow_graphic ) :
		$graphic_of{bg}->composite( graphic => $interim_graphic );

	my $expect_path = catfile( $FindBin::Bin, '04_images', 'expect_' . $test_name .  '.png' );

	my $expect_graphic = MMGraphic->new();
	if (-e $expect_path) {
		$expect_graphic->load_image( $expect_path );
	} else {
		diag( "Auto-passing test $shadow_name, $test_name" );
		$expect_graphic = $result_graphic->clone();
		$expect_graphic->save_image( $expect_path );
	}


	# If we fail the test, write actual result so we can what the problem is, and write difference image too
	my $diff_im = $options->{flatten} ?
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Drop shadow (flattened): $shadow_name / $test_name" ) :
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Drop shadow (result): $shadow_name / $test_name" );
	if ( $diff_im ) {
		$diff_im->Write( catfile( $FindBin::Bin, '04_images', 'diff_' . $result_name . '.png' ) );
		$result_graphic->save_image( catfile( $FindBin::Bin, '04_images', 'result_' . $result_name . '.png' ) );
	}
}

sub cmp_image {
	my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
	my $difference_img = $expect_img->Compare( image => $result_img, metric=>'rmse' );
	return if ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name );
  	return $difference_img;
}
