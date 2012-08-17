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

If you need to access a non-exposed L<Image::Magick> feature within a method
that is not documented here, or one that has been over-ridden by B<MMGraphic::Image>,
i.e. documented below, but that might have an additional parameter you need to use,
then you can. Simply access the C<image> property, which is the underlying
L<Image::Magick> object, and call the method directly on that:

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
        Color Set Separate Negate Blur
        Shade ContrastStretch SigmoidalContrast QuantumRange
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

=head2 Clone

Returns a copy of the current object, containing a copy of the
Image::Magick image.

=cut

method Clone {
    return __PACKAGE__->new( image => $self->image->Clone() );
}

=head2 _Color( $mmg_color )

All pixels in the image are set to C<$mmg_color>, which should be
a L<MMGraphic::Color> object or a hashref or string that will be passed to
L<MMGraphic::Color>'s constructor.

=cut


method _Color (
    Object $color!
    ) {
    _imtry {
        $self->image->Color(
            color => $color->as_image_magick_string()
        );
    };
    return;
}

=head2 Composite

Alters image by composing another one on top of it.

Returns nothing.

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

Copyright 2011 Neil SLATER.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MMGraphic::Image

