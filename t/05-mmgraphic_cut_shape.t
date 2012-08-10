use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use File::Spec::Functions;
use FindBin;

use MMGraphic;
use Image::Magick;

my %graphic_of = (
    bg => MMGraphic->new( image => catfile( $FindBin::Bin, '05_images', 'background.png' ) ),
	tx1 => MMGraphic->new( image => catfile( $FindBin::Bin, '05_images', 'texture_01.png' ) ),
);

##############################################################################
#
# The tests
#

create_graphic(qw(tx1 basic), { primitive => 'Rectangle', points => [[50,50],[75,75]], flatten => 1 });
create_graphic(qw(tx1 basic2), { primitive => 'Rectangle', points => [[50,50],[175,125]] });
create_graphic(qw(tx1 basic3), { primitive => 'Rectangle', points => [[150,150],[275,225]] });
create_graphic(qw(tx1 basic4), { primitive => 'Rectangle', points => [[150,150],[275,225]], border => 20 });
create_graphic(qw(tx1 basic5), { primitive => 'RoundRectangle', points => [[150,150],[275,225]],
	fixed_points => [[10,8]], flatten => 1 });


create_graphic(qw(tx1 basicst), { primitive => 'Rectangle', points => [[50,50],[75,75]], edge_colour => 'black' });
create_graphic(qw(tx1 basic3st), { primitive => 'Rectangle', points => [[150,150],[275,225]],
	edge_colour => 'yellow' });
create_graphic(qw(tx1 basic5st), { primitive => 'RoundRectangle', points => [[150,150],[275,225]],
	fixed_points => [[10,8]], flatten => 1, edge_colour => '#ffff00' });


exit;

sub create_graphic {
	my ( $texture_name, $test_name, $options ) = @_;
	$options ||= {};

	# The clone prevents changing loaded graphics on flattening
	my $texture_graphic = $graphic_of{ $texture_name }->clone();
	my $result_name = 'cs_' . $texture_name . '-' . $test_name;
	my $interim_graphic = $texture_graphic->cut_shape( %$options );

	my $result_graphic = $options->{flatten} ?
		$graphic_of{bg}->composite( graphic => $texture_graphic ) :
		$graphic_of{bg}->composite( graphic => $interim_graphic );

	my $expect_path = catfile( $FindBin::Bin, '05_images', 'expect_' . $test_name .  '.png' );

	my $expect_graphic = MMGraphic->new();
	if (-e $expect_path) {
		$expect_graphic->load_image( $expect_path );
	} else {
		diag( "Auto-passing test $texture_name, $test_name" );
		$expect_graphic = $result_graphic->clone();
		$expect_graphic->save_image( $expect_path );
	}


	# If we fail the test, write actual result so we can see what the problem is, and write difference image too
	my $diff_im = $options->{flatten} ?
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Cut shape (flattened): $texture_name / $test_name" ) :
		cmp_image( $result_graphic->image, $expect_graphic->image, 1, "Cut shape (result): $texture_name / $test_name" );
	if ( $diff_im ) {
		$diff_im->Write( catfile( $FindBin::Bin, '05_images', 'diff_' . $result_name . '.png' ) );
		$result_graphic->save_image( catfile( $FindBin::Bin, '05_images', 'result_' . $result_name . '.png' ) );
	}
}

sub cmp_image {
	my ( $result_img, $expect_img, $fuzz_percent, $test_name ) = @_;
	my $difference_img = $expect_img->Compare( image => $result_img->image, metric=>'rmse' );
	return if ok( $difference_img->Get('error') < $fuzz_percent/100, $test_name );
  	return $difference_img;
}
