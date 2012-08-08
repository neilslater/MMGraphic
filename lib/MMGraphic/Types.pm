package MMGraphic::Types;
use strict;
use warnings;
use Moose::Util::TypeConstraints;
use Image::Magick;

my $r; # To hold Image::Magick responses

=head1 NAME

MMGraphic::Types - type library for MMGraphic

=head1 DESCRIPTION

This module defines MMGraphic types and coercions for the C<Moose>
framework.

=head1 TYPES

=head2 IMImage

An C<Image::Magick> image object. Can be coerced from a string
(which loads the image data from file via the C<Read> method)
or from a MMGraphic object (which simply refers its
contained image object).

=cut

subtype 'IMImage' => as class_type('Image::Magick');

=head2 MMGraphicImage

A C<MMGraphic> object. Can be coerced from a string
(which loads the image data from file via Image::Magick's C<Read> method)
or from an Image::Magick object.

=cut

subtype 'MMGraphicImage' => as class_type('MMGraphic');

coerce 'IMImage'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $im = Image::Magick->new();
			$r = $im->Read( $_ );
			croak($r) if $r;
			$im;
			}
	=> from 'MMGraphicImage'
		=> via {
			# The Clone is not always necessary, but protects against
			# accidental cross-links of image objects between two
			# MMGraphic objects
			$_->image->Clone();
			};


coerce 'MMGraphicImage'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $im = Image::Magick->new();
			$r = $im->Read( $_ );
			croak($r) if $r;
			MMGraphic->new( image => $im );
			}
	=> from 'IMImage'
		=> via {
			MMGraphic->new( image => $_ );
		};

1;
