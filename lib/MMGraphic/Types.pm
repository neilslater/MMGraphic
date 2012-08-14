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

=head2 ImageMagickObject

An L<Image::Magick> image object.

=cut

subtype 'ImageMagickObject' => as class_type('Image::Magick');

=head2 MMGraphicImageObject

A L<MMGraphic::Image> object.

=cut

subtype 'MMGraphicImageObject' => as class_type('MMGraphic::Image');

=head2 MMGraphicObject

A L<MMGraphic> object.

=cut

subtype 'MMGraphicObject' => as class_type('MMGraphic');

=head1 COERCIONS

The types C<ImageMagickObject>, C<MMGraphicImageObject>, and C<MMGraphicObject>
all coerce between each other using the underlying L<Image::Magick>
object. In addition all three types will accept a string path to
an image file which they will load (using L<Image::Magick>'s
C<Read> method).

=cut

# For my own sanity, inside MMGraphic, I use the following object
# name "decorations":

# $<THING>_path    = string path to image file
# $<THING>_IM      = Image::Magick object
# $<THING>_image   = MMGraphic::Image object
# $<THING>_MMG     = MMGraphic object

# The two upper-cased names a deliberately eye-catching, as generally
# I expect to see $<THING>_image

coerce 'ImageMagickObject'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $IM = Image::Magick->new();
			$r = $IM->Read( $_ );
			croak($r) if $r;
			$IM;
        }
    => from 'MMGraphicImageObject'
        => via {
            # The Clone is not always necessary, but protects against
            # accidental cross-links of image objects between two
            # MMGraphic or MMGraphic::Image objects
            $_->image->Clone();
        }
	=> from 'MMGraphicObject'
		=> via {
			# The Clone is not always necessary, but protects against
			# accidental cross-links of image objects between two
			# MMGraphic or MMGraphic::Image objects
            $_->image->image->Clone();
        };

coerce 'MMGraphicImageObject'
    => from 'Str'
        => via {
            # TODO: co-erce from URL using LWP/GET ?
            my $IM = Image::Magick->new();
            $r = $IM->Read( $_ );
            croak($r) if $r;
            MMGraphic::Image->new( image => $IM );
            }
    => from 'ImageMagickObject'
        => via {
            MMGraphic::Image->new( image => $_ );
        }
    => from 'MMGraphicObject'
        => via {
            $_->image;
        };


coerce 'MMGraphicObject'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $IM = Image::Magick->new();
			$r = $IM->Read( $_ );
			croak($r) if $r;
            MMGraphic->new( image => MMGraphic::Image->new( image => $IM ) );
			}
	=> from 'ImageMagickObject'
		=> via {
            MMGraphic->new( image => MMGraphic::Image->new( image => $_ ) );
		}
    => from 'MMGraphicImageObject'
        => via {
            MMGraphic->new( image => $_ );
        };

1;
