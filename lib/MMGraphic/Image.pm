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

=head1 DESCRIPTION

MMGraphic::Image is a Moose-y wrapper for L<Image::Magick>. It provides near
identical functionality to L<Image::Magick>, but changes calling conventions
and error handling. In general, all documented
methods are wrapped with the following changes to behaviour:

=over

=item B<Parameters>

Differ as documented, some attempts have been made to make them more
type-friendly and consistent between Image Magick versions.
All are validated to some degree before calling the underlying
L<Image::Magic> method.

=item B<Errors>

Are thrown as exceptions. There is no need to inspect return values for
possible errors.

=item B<Image Alterations>

Are by default returned as a new MMGraphic::Image object.
To change this behaviour, the parameter C<flatten>
can be supplied with a true value.

=item B<Return Values>

Differ as documented, and some attempts have been made to provide
type friendly or object-oriented values when appropriate.

=back

If an L<Image::Magick> method is I<not> documented below, it is still
available via this class, but it will be passed through directly to
L<Image::Magick> and will behave as documented in that module.

As of version 0.2, only the minority of methods and parameters allowed
by L<Image::Magick> have been implemented in this way by B<MMGraphic::Image>.
The initial goal is to cover all the functionality required by L<MMGraphic>.

=head1 PROPERTIES

=head2 image

An L<Image::Magick> image.

You can set the value using a scalar file path, or another MMGraphic::Image
object (for both of these cases, MMGraphic::Image creates a I<new>
L<Image::Magick> object internally).

I<Warning>! MMGraphic::Image does not check for multiple references to the same
L<Image::Magick> object. Unpredictable things may happen if you instantiate
multiple MMGraphic objects with the exact same L<Image::Magick> object and
then process them differently.

If you want to have multiple B<MMGraphic::Image> objects initialised from the same base
image, you can avoid this issue by using constructor options of scalar file
paths or B<MMGraphic::Image> objects. Alternatively, you can make use of the
C<Clone> method.

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

=head3 graphic

Several methods combine two or more graphics to produce a new image.

Any C<graphic> or C<< <foo>_graphic >> parameter will accept any
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

Methods in B<MMGraphic::Image> tend to take C<graphic> or C<< <foo>_graphic >>
parameters where L<Image::Magick> would take an C<image> as a parameter.

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

=item B<graphic>

A graphic that will be inserted over the existing image.

This is the only mandatory parameter.

See L<Common Parameters (graphic)|/graphic>.

=item B<x> and B<y>

Co-ordinates to use for C<graphic>, defaults to 0,0.

=item B<compose>

Compose mode for C<graphic>, defaults to 'Over'.

=back

=cut

method Composite (
    MMGraphicImageObject :$graphic! does coerce,
    MMGraphicImageObject :$mask_graphic does coerce,
    Str :$compose = 'Over',
    Str :$opacity,
    Num :$x = 0,
    Num :$y = 0
    ) {
    _imtry {
        $self->image->Composite(
            image => $graphic->image,
            compose => $compose,
            $mask_graphic ? ( mask => $mask_graphic->image ) : (),
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

