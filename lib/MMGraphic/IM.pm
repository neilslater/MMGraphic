package MMGraphic::IM;
use Moose;
use Carp;
use MMGraphic::Types;

use Image::Magick;
use MooseX::Method::Signatures;

my $r; # Temp holder for Image::Magick responses . . .

our $AUTHOR = 'Neil Slater';
our $VERSION = '0.2';

=head1 NAME

MMGraphic::IM - Wraps Image::Magick with more Moose-y behaviour

=head1 DESCRIPTION

MMGraphic::IM is a Moose-y wrapper for L<Image::Magick>. It provides near
identical functionality to L<Image::Magick>, except that all documented
methods are wrapped with the following changes to behaviour:

=over

=item B<Parameters>

Differ as documented, some attempts have been made to make them more
type-friendly and consistent between Image Magic versions.
All are validated to some degree before calling the underlying
L<Image::Magic> method.

=item B<Errors>

Are thrown as exceptions. There is no need to inspect return values for
possible errors.

=item B<Image Alterations>

Are by default returned as a new MMGraphic::IM object.
To change this behaviour, the parameter C<flatten>
can be supplied with a true value.

=item B<Return Values>

Differ as documented, and some attempts have been made to provide
type friendly or object-oriented values when appropriate.

=back

If an L<Image::Magick> method is I<not> documented below, it is still
available via this class, but it will be passed through directly to
L<Image::Magick> and will behave as documented in that module.

=head1 PROPERTIES

=head2 image

An L<Image::Magick> image.

You can set the value using a scalar file path, or another MMGraphic::IM
object (for both of these cases, MMGraphic::IM creates a I<new>
L<Image::Magick> object internally).

I<Warning>! MMGraphic::IM does not check for multiple references to the same
L<Image::Magick> object. Unpredictable things may happen if you instantiate
multiple MMGraphic objects with the exact same L<Image::Magick> object and
then process them differently.

If you want to have multiple MMGraphic::IM objects initialised from the same base
image, you can avoid this issue by using constructor options of scalar file
paths or MMGraphic::IM objects. Alternatively, you can make use of the
C<Clone> method.

=cut

has 'image' => (
	is => 'rw',
	isa => 'IMImage',
	default => sub { Image::Magick->new();},
	coerce => 1,
    handles => [qw(
        Read Write Composite Color Set Separate Negate Blur
        Shade ContrastStretch SigmoidalContrast QuantumRange
        Colorize Crop Draw Get ReadImage Compare
    )],
);

=head1 METHODS

=head2 Common Parameters

=head3 flatten

Many of MMGraphic::IM's methods alter the contained image.

By default, those methods create and return a new MMGraphic
object. which in turn contains a new L<Image::Magick> object.

If you provide a true value for C<flatten>, then the methods will
alter the image data within the current object instead.

=head3 graphic

Several methods combine two or more graphics to produce a new image.

The C<graphic> parameter will accept any of the following values:

=over

=item B<*>

An object of this class, C<MMGraphic::IM>

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

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Neil SLATER.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MMGraphic::IM

