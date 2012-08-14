package MMGraphic;
use Moose;
use Carp;
use MMGraphic::Types;

use MMGraphic::Image;
use Image::Magick;
use List::AllUtils qw(min max);
use MooseX::Method::Signatures;

my $r; # Temp holder for Image::Magick responses . . .

our $AUTHOR = 'Neil Slater';
our $VERSION = '0.2';

=head1 NAME

MMGraphic - (M)oose and Image::(M)agick Graphics

=head1 DESCRIPTION

MMGraphic provides some high-level routines for manipulating images. These
routines encapsulate knowledge about how to perform certain transformations
in L<Image::Magick>.

The contained L<Image::Magick> object can be accessed indirectly via
the C<image> property.

Using the Moose framework it is very easy to sub-class MMGraphic and add
your own high-level image management routines.

=head1 INSTALLATION

The Image Magick library and Perl bindings do not install via CPAN. Before
you can use MMGraphic, you need to install them directly.

Please see http://www.imagemagick.org/ for details.

=head1 PROPERTIES

=head2 image

A L<MMGraphic::Image> wrapper object to L<Image::Magic>.

You can set the value using a scalar file path, or another MMGraphic object
(for both of these cases, MMGraphic creates a new L<Image::Magick> object).

I<Warning>! MMGraphic does not check for multiple references to the same
L<MMGraphic::Image> object. Unpredictable things may happen if you instantiate
multiple MMGraphic objects with the exact same L<MMGraphic::Image> object and
then process them differently.

If you want to have multiple MMGraphic objects initialised from the same base
image, you can avoid this issue by using constructor options of scalar file paths or
MMGraphic objects. Alternatively, you can make use of the C<clone> method.

=cut

has 'image' => (
	is => 'rw',
    isa => 'MMGraphicImageObject',
	default => sub { MMGraphic::Image->new();},
	coerce => 1,
);

=head1 METHODS

=head2 Common Parameters

=head3 flatten

Many of MMGraphic's methods alter the contained image.

By default, those methods create and return a new MMGraphic
object. which in turn contains a new L<MMGraphic::Image> object (which
in turn contains a new L<Image::Magick> object).

If you provide a true value for C<flatten>, then those methods will
alter the image data within the current object instead.

=head3 graphic

Several methods combine two or more graphics to produce a new image.

Any C<graphic> or C<< <foo>_graphic >> parameter will generally
accept any of the following values:

=over

=item B<*>

An object of this class, C<MMGraphic>

=item B<*>

An object of the C<MMGraphic::Image> class.

=item B<*>

An object of class L<Image::Magick>

=item B<*>

A scalar path to an image file (loaded using L<Image::Magick>'s C<Read> method).

=back

=head2 clone

Returns a copy of the current object, containing a copy of the
MMGraphic::Image image.

=cut

method clone {
	return __PACKAGE__->new( image => $self->image->Clone );
}

=head2 load_image( $filename )

Discards current C<image> value, replacing it with the data
from the file.

=cut

method load_image (Str $file_name) {
	my $image = MMGraphic::Image->new();
	$image->Read( $file_name );
	$self->image( $image );
	return;
}

=head2 save_image( $filename )

Saves the current C<image> to a named file.

=cut

method save_image (Str $file_name) {
	$self->image->Write( $file_name );
	return;
}

=head2 composite( graphic => $graphic, x => $x, y => $y )

Alters image by composing another one on top of it.

Return value depends on the C<flatten> parameter.

=over

=item B<flatten>

See L<Common Parameters (flatten)|/flatten>.

=item B<graphic>

A graphic that will be inserted over the existing image.

This is the only mandatory parameter.

See L<Common Parameters (graphic)|/graphic>.

=item B<x> and B<y>

Co-ordinates to use for C<graphic>, defaults to 0,0.

=item B<compose>

Compose mode for C<graphic>, defaults to 'Over'.

=item B<mask>

Optional, a hash reference of parameters for masking to be
applied to the graphic before composing. See C<apply_mask>
for allowed parameters and their meanings.

=item B<opacity>

Optional, a number from 0 to 100 that controls overall
opacity applied to the composite. This works in addition to
the mask image, if both parameters are provided. The default
is 100 (fully opaque).

=back

=cut

method composite (
	MMGraphicObject :$graphic! does coerce,
	Bool :$flatten,
	HashRef :$mask,
	Str :$compose = 'Over',
	Num :$opacity = 100,
	Num :$x = 0,
	Num :$y = 0
	) {
	my $src_graphic = $graphic->clone();

	my %options = ( compose => $compose, x => $x, y => $y );

	if ( ref($mask) eq 'HASH' ) {
		$src_graphic->apply_mask( flatten => 1, %$mask );
	}

	my $result_im = $self->image->Clone;

	$result_im->Composite( graphic => $src_graphic, %options );

	# Dealing with opacity whilst respecting compose choice and
	# potential transparency in the final image is complicated. Effectively
	# we mask again with a greyscale image and compose that on top of original
	if ( $opacity < 100 ) {
		my $result_layer_im = $result_im;
		$result_im = $self->image->Clone;

		my $temp_mask_im = $result_layer_im->Clone;
		$temp_mask_im->Color( "rgb($opacity\%, $opacity\%, $opacity\%)" );
		$temp_mask_im->Set(alpha=>"Off");
 		croak($r) if $r;

		my $combined_mask = $result_layer_im->Clone;
		croak($r) if $r;

		$r = $combined_mask->Separate( channel => 'Opacity' );
		croak($r) if $r;

		$r = $combined_mask->Negate();
		croak($r) if $r;

		$combined_mask->Composite( graphic => $temp_mask_im, compose => 'Multiply' );

		$combined_mask->Set(alpha=>"Off");
		croak($r) if $r;

		$result_layer_im->Composite( graphic => $combined_mask, compose => 'CopyOpacity'  );

		$result_im->Composite( graphic => $result_layer_im );
	}

	return $flatten ? $self->_flatten( $result_im ) : __PACKAGE__->new( image => $result_im );
}


=head2 emboss

Alters image into a bump map, suitable for use as a parameter to C<composite>.

Return value depends on the C<flatten> parameter.

Parameters are:

=over

=item B<flatten>

See L<Common Parameters (flatten)|/flatten>.

=item B<theta>

Angle of light source, in degrees - C<0> represents a light shining along x-axis from
positive to negative. Positive values of theta are anti-clockwise. Default 120
(light shining from just above "North West").

=item B<blur>

Amount of blur (in pixels) to apply before creating bump map. Default
value is 2.

=item B<contrast>

Value from 0 to 20 (default 5) controlling tightness of highlights.

=item B<mix>

Value from 0 to 100 (default 90) controlling difference from mid grey
on bumps.

=item B<valley_darken>

Value from 0 to 100 (default 0) that darkens valley areas in addition
to slope lighting

=item B<valley_blur>

Softening for valley effects.

=back

=cut


# Source: Author: Anthony Thyssen, <A.Thyssen@griffith.edu.au>
# http://www.imagemagick.org/Usage/transform/#shade
# NB 21.78 elevation generates usable mid-grey when combined with the sigmoidal operator
#In summary, the above example has four separate controls...
#    "blur" : Rounding the shape edges (0.001=beveled 2=smoothed 10=rounded)
#    "shade" : The direction the light is coming from (120=top-left 60=top-right)
#    "sigmoidal" : surface reflective control highlight spots (1=flat 5=good 10=reflective )
#    "colorize" : Overall contrast of the highlight ( 0%=bright 10%=good 50%=dim )

method emboss (
	Bool :$flatten,
	Num :$blur = 2,
	Num :$theta = 120,
	Num :$contrast = 5,
	Num :$mix = 90,
	Num :$valley_darken = 0,
	Num :$valley_blur = 5
	) {
	my $result_im = $self->image->Clone();

	$r = $result_im->Set( 'virtual-pixel' => 'Tile' );
	croak($r) if $r;

	$r = $result_im->Blur( sigma => $blur  );
	croak($r) if $r;

	$r = $result_im->Shade( geometry => $theta . 'x21.78', gray => 'true' );
	croak($r) if $r;

	$r = $result_im->ContrastStretch( '0%' );
	croak($r) if $r;

	$r = $result_im->SigmoidalContrast( 'mid-point' => 0.5 * $result_im->QuantumRange, contrast => $contrast );
	croak($r) if $r;

	my $opacity = int( 100 - $mix ) . '%';
	$r = $result_im->Colorize( fill => 'grey50', opacity => $opacity );
	croak($r) if $r;

	if ( $valley_darken ) {
		my $valley_mask_im = $self->image->Clone();
		$r = $valley_mask_im->Set( 'virtual-pixel' => 'Tile' );
		croak($r) if $r;

		$r = $valley_mask_im->Negate();
		croak($r) if $r;

		$r = $valley_mask_im->Blur( sigma => $valley_blur );
		croak($r) if $r;

		my $valley_darken_im = $self->image->Clone();
		$r = $valley_darken_im->Colorize( fill => 'black', opacity => '100%' );
		croak($r) if $r;

		my $darken_opacity = int( $valley_darken ) . '%';
		
		$result_im->Composite( graphic => $valley_darken_im, mask_graphic => $valley_mask_im,
			opacity => $darken_opacity, compose => 'Overlay' );
	}

	return $flatten ? $self->_flatten( $result_im ) : __PACKAGE__->new( image => $result_im );
}

=head2 apply_mask( graphic => $graphic )

This alters the image by masking with the supplied mask image.
The resulting image is always 4 channel (including an alpha channel),
irrespecive of the source images.

Return value depends on the C<flatten> parameter.

=over

=item B<flatten>

See L<Common Parameters (flatten)|/flatten>.

=item B<graphic>

Mandatory parameter. The graphic that will be used to mask
the existing image.

See L<Common Parameters (graphic)|/graphic>.

=item B<use_alpha>

Set true if the result should be based on the mask's alpha channel.

=item B<negate>

If true the mask is negated before being used.

=item B<feather>

If supplied the mask is blurred by this amount before use.

=back

=cut

method apply_mask (
    MMGraphicImageObject :$graphic! does coerce,
	Bool :$flatten,
	Bool :$use_alpha,
	Bool :$negate,
	Num :$feather = 0
	) {
	my $mask_im = $graphic->Clone();

	if ( $use_alpha ) {
		$r = $mask_im->Separate( channel => 'Opacity' );
		croak($r) if $r;
		$r = $mask_im->Negate();
		croak($r) if $r;
	} else {
		$mask_im->Set(alpha=>"Off");
 		croak($r) if $r;
	}

	if ($negate) {
		$r = $mask_im->Negate();
		croak($r) if $r;
	}

	if ($feather) {
		$r = $mask_im->Blur( sigma => $feather );
		croak($r) if $r;
	}

	# Create a combined mask which multiplies both sets of alpha channels
	#     Mask from $this_image is greyscale of alpha channel
	#     Mask from $mask is either as supplied or an extract of the alpha channel

	my $combined_mask = $self->image->Clone;
	croak($r) if $r;

	$r = $combined_mask->Separate( channel => 'Opacity' );
	croak($r) if $r;

	$r = $combined_mask->Negate();
	croak($r) if $r;

	$combined_mask->Composite( graphic => $mask_im, compose => 'Multiply' );

	$combined_mask->Set(alpha=>"Off");
	croak($r) if $r;

	my $result_im = $self->image->Clone;
	
	$result_im->Composite( graphic => $combined_mask, compose => 'CopyOpacity'  );
	
	return $flatten ? $self->_flatten( $result_im ) : __PACKAGE__->new( image => $result_im );
}

=head2 drop_shadow( blur => 10 )

This alters the image by adding a drop shadow area "under" the original image,
using the alpha channel to determine which areas need to have shade added.

Return value depends on the C<flatten> parameter.

=over

=item B<flatten>

See L<Common Parameters (flatten)|/flatten>.

=item B<blur>

Amount to blur the shadow area after enlarging it. Defaults to 5.

=item B<enlarge>

Amount of "edge" in pixels to add to the original image. Defaults to 5.

=item B<offset_x> and B<offset_y>

Vector adjustment, in pixels, of shadow area.

=item B<opacity>

Opacity of the shadow effect. Defaults to 80%.

=item B<shadow_colour>

Defaults to 'black', any L<Image::Magick> colour string is
accepted.

=item B<shadow_graphic>

If supplied then used to create the shadow area instead of the fill
colour. This parameter effectively over-rides C<shadow_colour>.

This parameter may be supplied in multiple ways. See
L<Common Parameters|/Common Parameters>.

=item B<shadow_only>

If supplied and true, the result contains just
the shadow image and none of the original image.

=back

=cut

method drop_shadow (
	Bool :$flatten,
	Num :$blur = 5,
	Num :$enlarge = 10,
	Num :$offset_x = 0,
	Num :$offset_y = 0,
	Num :$opacity = 80,
	Str :$shadow_colour = 'black',
	MMGraphicObject :$shadow_graphic? does coerce,
	Bool :$shadow_only
	) {
	my $orig = $self->image();
	my ($sg,$sm); # Shadow Graphic, Shadow Mask

	if ( $shadow_graphic ) {
		$sg = $shadow_graphic->clone();
	} else {
		my $sized_im = $orig->Clone();
		$r = $sized_im->Color( $shadow_colour );
		croak($r) if $r;
		$sg = __PACKAGE__->new( image => $sized_im );
	}

	# Create shadow mask based on object's opacity
	$sm = $orig->Clone();
	$r = $sm->Separate( channel => 'Opacity' );
	croak($r) if $r;
	$r = $sm->Negate();
	croak($r) if $r;
	$r = $sm->Set( 'virtual-pixel' => 'Edge' );
	croak($r) if $r;

	# Enlarge shadow mask by blurring and applying strong contrast
	$r = $sm->Blur( sigma => $enlarge );
	croak($r) if $r;
	$r = $sm->SigmoidalContrast(
		'mid-point' => 0.2 * $sm->QuantumRange,
		contrast => 100 );
	croak($r) if $r;

	# Reduce shadow strength
	my $darken_opacity = int( 100 - $opacity ) . '%';
	$r = $sm->Colorize( fill => 'black', opacity => $darken_opacity ) if ($opacity < 100);
	croak($r) if $r;

	# Calculate shadow
	$sg->apply_mask( graphic => $sm, feather => $blur, flatten => 1 );

	# If there's an offset, resolve it by composing image over a transparent background in new
	# position
	if ( $offset_x != 0 || $offset_y != 0 ) {
		my $m = $self->_matching_layer();
		$m->composite( graphic => $sg, x => $offset_x, y => $offset_y, flatten => 1 );
		$sg->image( $m->image );
	}

	if ( $shadow_only ) {
		if ( $flatten )	{
			$self->_flatten( $sg->image );
			return $self;
		}
		return $sg;
	}

	return $self->composite( graphic => $sg, flatten => $flatten, compose => 'DstOver' );
}

=head2 cut_shape

This creates a new textured shape from the graphic, using L<Image::Magick>'s
Draw method. The new image has an alpha channel for compositing, and
is closely cropped to the final shape.

=over

=item B<flatten>

See L<Common Parameters (flatten)|/flatten>.

=item B<primitive>

Mandatory, must be one of L<Image::Magick>'s drawing primitives.

=item B<points>

Mandatory, an array ref containing array refs of [x,y] co-ordinates that
are used in the shape.

=item B<fixed_points>

Optional, an array ref containing array refs of [x,y] co-ordinates that
need to be used with fixed values at the end of the points list. For
example, the I<RoundRectangle> shape requires one fixed co-ordinate
that describes how large the corners are.

=item B<border>

Size of border area, in pixels, to use creating the cut-out image.
Defaults to 3.

=item B<edge_colour>

If supplied as a valid L<Image::Magick> colour, then the edge pixels
will be rendered in this colour, not using the texture.


=back

=cut

method cut_shape (
	Bool :$flatten,
	ArrayRef[ArrayRef] :$points!,
	ArrayRef[ArrayRef] :$fixed_points = [],
	Str :$primitive!,
	Num :$border = 3,
	Str :$edge_colour
	) {
	_assert_points_array( $points );
	croak "The points array must contain at least one entry." unless (@$points);
	_assert_points_array( $fixed_points );

	my ( $target_pts, $normalised_bounds, $offset) = _normalised_bounds( $points, $border );
	my $texture_bounds = _bounding_rect( $points, $border );

	my $tx_crop = $self->image->Clone();
	$r = $tx_crop->Crop( geometry => _arrayref_to_imgeo( $texture_bounds ) );
	croak($r) if $r;

	my $shape_im = _image_rect( @{$normalised_bounds->[1]} );

	my $draw_pts_txt = _arrayref_to_impoints( [@$target_pts,@$fixed_points] );
	if ( defined $edge_colour ) {
		$r = $shape_im->Draw(
			primitive => $primitive,
			tile => $tx_crop->image,
			points => $draw_pts_txt,
			antialias => 'true',
			stroke => $edge_colour,
			);
		croak($r) if $r;
	} else {
		$r = $shape_im->Draw(
			primitive => $primitive,
			tile => $tx_crop->image,
			points => $draw_pts_txt,
			antialias => 'true',
			);
		croak($r) if $r;
	}

	return $flatten ? $self->_flatten( $shape_im ) : __PACKAGE__->new( image => $shape_im );
}


#####################################################################################
#
#  "Private" methods
#

sub _flatten {
	my ($self, $new_image) = @_;
	$self->image( $new_image );
	return $self;
}

sub _matching_layer {
	my ($self) = @_;
	my ($w,$h) = $self->image->Get( 'width', 'height' );
	return __PACKAGE__->new( image => _image_rect( $w, $h ) );
}

#####################################################################################
#
#  Utils.
#

sub _assert_points_array {
	my ($points) = @_;
	croak "Points must be an array ref." unless (ref($points) eq 'ARRAY');
	for my $pt (@$points) {
		_assert_point($pt);
	}
}

sub _assert_point {
	my ($pt) = @_;
	croak "A point must be an array ref with two elements" unless
		(ref($pt) eq 'ARRAY' && @$pt == 2);
	croak "Not a point: ( $pt->[0], $pt->[1] )" unless
		(defined $pt->[0] && $pt->[0] =~ /-?[\d]*\.?[\d]+/ &&
		defined $pt->[1] && $pt->[1] =~ /-?[\d]*\.?[\d]+/);
}

# Returns two array refs - first is a "centralised" array of input, second is offset
# to apply that will put it in correct position. Centralisation is done to truncated values
# to avoid "partial pixel" issues.
sub _centre_offset {
	my ( $points ) = @_;
	my $bounds = _bounding_rect( $points );
	my $offset_x = int( 0.5 * ( $bounds->[0][0] + $bounds->[1][0] ) );
	my $offset_y = int( 0.5 * ( $bounds->[0][1] + $bounds->[1][1] ) );
	return (_offset_points($points,[-$offset_x,-$offset_y]), [$offset_x,$offset_y]);
}

# Returns three array refs - first is a "centralised" array of input, second is bounding
# rectangle for that array, Third is offset array for the rectangle that would place points
# back in position
sub _normalised_bounds {
	my ( $points, $border ) = @_;
	my $bounds = _bounding_rect( $points, $border );
	my $offset_x = $bounds->[0][0];
	my $offset_y = $bounds->[0][1];
	return (
		_offset_points($points,[-$offset_x,-$offset_y]),
		_offset_points($bounds,[-$offset_x,-$offset_y]),
		[$offset_x,$offset_y]
		);
}

# Returns array ref of array refs representing bounding rectangle for set of points
sub _bounding_rect {
	my ( $points, $border ) = @_;
	$border ||= 0;

	my @all_x = map { $_->[0] } @$points;
	my $min_x = min(@all_x);
	my $max_x = max(@all_x);

	my @all_y = map { $_->[1] } @$points;
	my $min_y = min(@all_y);
	my $max_y = max(@all_y);

	return [ [$min_x-$border,$min_y-$border], [$max_x+$border,$max_y+$border] ];
}

# Returns IM-style string of co-ordinates from array ref
sub _arrayref_to_impoints {
	my ( $points ) = @_;
	return join(' ', map { join(',', @$_) } @$points );
}

# Returns IM-style string of co-ordinates from array ref
sub _arrayref_to_imgeo {
	my ( $points ) = @_;
	my ($x,$y,$w,$h) = map {int($_+0.5)} ($points->[0][0],$points->[0][1],$points->[1][0]-$points->[0][0],$points->[1][1]-$points->[0][1]);
	return $w . 'x' . $h . '+' . $x . '+' . $y;
}

# Returns IM-style string of co-ordinates from array ref
sub _arrayref_to_imsize {
	my ( $points ) = @_;
	my ($x,$y,$w,$h) = ($points->[0][0],$points->[0][1],$points->[1][0]-$points->[0][0],$points->[1][1]-$points->[0][1]);
	return $w . 'x' . $h;
}

# Returns perl array ref of co-ordinates from IM style string of co-ordinates
sub _impoints_to_arrayref {
	my ( $impoints ) = @_;
	return [ map { [ split(',',$_) ] } split(/\s+/, $impoints) ];
}

# Returns new array ref of points offset by supplied values
sub _offset_points {
	my ( $points, $offset ) = @_;
	return [ map { [ $_->[0] + $offset->[0], $_->[1] + $offset->[1] ] } @$points ];
}

sub _image_rect {
	my ($w, $h, $fill ) = @_;
	$fill ||= 'NULL:transparent';
	my $blank = Image::Magick->new();
	$blank->Set( size => "${w}x${h}" );
	$r = $blank->ReadImage( $fill );
	croak($r) if $r;
	$r = $blank->Set( "background", "rgba(255,255,255,0)" );
	croak($r) if $r;
	return $blank;
}


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Neil SLATER.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MMGraphic
