package MMGraphic::Image;
use Moose;
use Carp;

use Image::Magick;
use MooseX::Method::Signatures;
use MMGraphic::Types;
use namespace::autoclean;

sub _imtry(&); # Wrapper to throw exceptions

our $AUTHOR = 'Neil Slater';
our $VERSION = '0.2';

=head1 NAME

MMGraphic::Image - Wraps Image::Magick with more Moose-y behaviour

=head1 SYNOPSIS

    use MMGraphic::Image;

    $pic = MMGraphic::Image->new( '/tmp/photo.jpg' );
    $pic->Negate();
    $pic->Write( '/tmp/photo_negative.jpg' );

=head1 DESCRIPTION

B<MMGraphic::Image> is a Moose-y wrapper for L<Image::Magick>. It provides a
small subset of L<Image::Magick>'s full behaviour.

You may need to access a non-exposed L<Image::Magick> feature within a method
that is not documented here. Or perhaps need to access a method that has been
over-ridden by B<MMGraphic::Image>, i.e. documented below, but that has an 
additional parameter you need to use. To do so, simply access the C<image>
property, which is the underlying L<Image::Magick> object, and call the 
method you need directly on that:

  my $result = $mmg_image->image->Mogrify( ... );
  croak($result) if $result;

=head1 ATTRIBUTES

=head2 image

An L<Image::Magick> image.

You can set the value using a scalar file path, or another B<MMGraphic::Image>
object.

I<Warning>! MMGraphic::Image does not check for multiple references to the same
underlying objects. Unpredictable things may happen if you instantiate
multiple MMGraphic objects with the exact same L<Image::Magick> object and
then process them differently.

=cut

has 'image' => (
    is => 'rw',
    isa => 'ImageMagickObject',
    default => sub { Image::Magick->new();},
    coerce => 1,
    handles => [qw(
        QuantumRange
        Colorize Crop Draw Get ReadImage Compare
    )],
);

=head1 METHODS

=head2 Common Parameters

=head3 image

Several methods combine two or more images to produce a new image.

Any C<image> or C<< <foo>_image >> parameter will accept any
of the following values:

=over

=item B<*>

An object of this class, B<MMGraphic::Image>

=item B<*>

An object of the higher-level image manipulating class,
L<MMGraphic>

=item B<*>

An object of class L<Image::Magick>

=item B<*>

A scalar path to an image file (loaded using L<Image::Magick>'s C<Read> method).

=back

=head2 Blur

Averages between pixels that are close together, visually softening the
image.

Returns: Nothing.

Parameters:

=over

=item B<sigma>

Feature size of the blur effect, as a numeric distance (in pixels).
Mathematically this is related to a Gaussian used to share each pixel
value with its neighbours.

=back

Blur results close to the image edges are affected by
the C<virtual-pixel> image property.

=cut

method Blur (
    Num :$sigma!
    ) {
    _imtry {
        $self->image->Blur(
            sigma => $sigma
        );
    };
    return;
}

=head2 Clone

Returns a copy of the current object, containing a copy of the
Image::Magick image.

Parameters: None

=cut

method Clone {
    return __PACKAGE__->new( image => $self->image->Clone() );
}

=head2 Color( $mmg_color )

All pixels in the image are set to C<$mmg_color>, which is a string
color description suitable for L<Image::Magick>.

Returns: Nothing.

Parameter: Takes a single scalar value, which must describe a color
choice available in L<Image::Magick>.

=cut

# TODO: Create and use MMGraphic::Color class instead

method Color (
    Str $color!
    ) {
    _imtry {
        $self->image->Color(
            color => $color
        );
    };
    return;
}

=head2 Composite

Alters image by composing another one on top of it.

Returns nothing.

Parameters:

=over

=item B<image>

An image that will be combined over the existing image.

This is the only mandatory parameter.

See L<Common Parameters (image)|/image>.

=item B<x> and B<y>

Co-ordinates to use for C<graphic>, defaults to 0,0.

=item B<compose>

Compose mode for C<graphic>, defaults to 'Over'.

=item B<mask>

An optional mask image that controls the degree of
composite applied.

See L<Common Parameters (image)|/image>.

=back

=cut

method Composite (
    MMGraphicImageObject :$image! does coerce,
    MMGraphicImageObject :$mask does coerce,
    Str :$compose = 'Over',
    Str :$opacity,
    Num :$x = 0,
    Num :$y = 0
    ) {
    _imtry {
        $self->image->Composite(
            image => $image->image,
            compose => $compose,
            $mask ? ( mask => $mask->image ) : (),
            $opacity ? ( opacity => $opacity ) : (),
            x => $x,
            y => $y
        );
    };
    return;
}

=head2 ContrastStretch( $amount )

Increases or decreases variance in value/brightness.

Parameter: scalar amount, e.g. C<'0%'>

Returns: Nothing.

=cut

# TODO: Better understanding and description required

method ContrastStretch (
    Str $amount
    ) {
    _imtry {
        $self->image->ContrastStretch( $amount );
    };
    return;
}

=head2 Negate( )

Inverts all image channels except Opacity, creating an
image "Negative".

Parameters: None

Returns: Nothing

=cut

method Negate () {
    _imtry {
        $self->image->Negate();
    };
    return;
}

=head2 Read( $file_name )

Discards currently stored image data, and replaces with data
read from file.

=cut

method Read (Str $file_name) {
    my $IM = Image::Magick->new();

    _imtry { $IM->Read( $file_name ); };

    $self->image( $IM );
    return;
}

=head2 Separate( channel => $channel_name )

Converts image to greyscale, based on single image
channel (such as "Red" or "Opacity")

Parameters:

=over

=item B<channel>

String name of the channel, e.g. C<Opacity>

=back

=cut

# TODO: Enumerate allowed channel names, add remaining params

method Separate (
    Str :$channel!
    ){
    _imtry {
        $self->image->Separate(
            channel => $channel
        );
    };
    return;
}

=head2 Set( image_property => $new_value, ... )

Writes one or more image properties

=cut

# TODO: Itemise (in code and docs) params and validate them

sub Set {
    my ($self,%params) = @_;
    _imtry {
        $self->image->Set(
            %params
        );
    };
    return;
}

=head2 Shade( geometry => '<angle1>x<angle2>', gray => 'true' )

Turns image into a height map and simulates a parallel light
source shining on it.

Parameters:

=over

=item B<geometry>

A string of form C<< <angle1>x<angle2> >>, where the first angle
is anti-clockwise degrees from positive x axis, and second angle
is elevation.

=item B<gray>

An optional string. If provided with value "true", calculates
height field using a gray value calculation.

=back

=cut

# TODO: Handle geometry better, confirm grayness algorithm and alternatives

method Shade (
    Str :$geometry!,
    Str :$gray
    ){
    _imtry {
        $self->image->Shade(
            geometry => $geometry,
            $gray ? ( gray => $gray ) : (),
        );
    };
    return;
}

=head2 SigmoidalContrast( 'mid-point' => 0.5 , contrast => $contrast )

Alters contrast on image by applying an S-shaped curve that maps the 
old value to new value. With a low contrast value, the 

Parameters:

=over

=item B<mid-point>

The current gray value that will be turned into a mid-gray by the contrast
effect. The value C<0.5> is 50% gray - this differs from L<Image::Magick>
which takes channel value e.g. 128 or 2000000, which will behave differently
for 8-bit and 16-bit Image::Magick libraries.

=item B<contrast>

Contrast effect. Values below 1 reduce contrast with a flat curve. Higher
values have a more S-shaped curve. Very high values are effectively a vertical
line through the C<mid-point> value.

=back

Returns: Nothing.

=cut

# TODO: Handle geometry better, confirm grayness algorithm and alternatives

sub SigmoidalContrast {
    my ($self, %params) = @_;
    my $mid_point = $params{'mid-point'} || croak "Missing parameter 'mid-point'";
    my $contrast = $params{'contrast'} || croak "Missing parameter 'contrast'";
    _imtry {
        $self->image->SigmoidalContrast(
            'mid-point' => $mid_point * $self->QuantumRange,
            contrast => $contrast,
        );
    };
    return;
}

=head2 Write( $file_name )

Stores image in named file. Uses the file extension
to determine which of the many supported image formats
to use.

=cut

method Write (Str $file_name) {
    _imtry { $self->image->Write( $file_name ); };
    return;
}

__PACKAGE__->meta->make_immutable;

#######################################################################
#
# private subs
#

# _imtry CODE
# Wraps code with check for return value and throws it as exception
# if there is one. Standard way that many Image::Magick manipulation
# subs behave.
sub _imtry(&) {
    my ($code) = @_;
    my $r = &$code;
    croak($r) if $r;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Neil SLATER.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MMGraphic::Image

