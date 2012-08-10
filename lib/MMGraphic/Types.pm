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

An L<Image::Magick> image object.

=cut

subtype 'IMImage' => as class_type('Image::Magick');

=head2 MMGraphicIMWrapper

A L<MMGraphic::IM> object.

=cut

subtype 'MMGraphicIMWrapper' => as class_type('MMGraphic::IM');

=head2 MMGraphicImage

A L<MMGraphic> object.

=cut

subtype 'MMGraphicImage' => as class_type('MMGraphic');

=head1 COERCIONS

The types C<IMImage>, C<MMGraphicIMWrapper>, and C<MMGraphicImage>
all coerce between each other using the underlying L<Image::Magick>
object. In addition all three types will accept a string path to
an image file which they will load (using L<Image::Magick>'s
C<Read> method).

=cut

coerce 'IMImage'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $im = Image::Magick->new();
			$r = $im->Read( $_ );
			croak($r) if $r;
			$im;
        }
    => from 'MMGraphicIMWrapper'
        => via {
            # The Clone is not always necessary, but protects against
            # accidental cross-links of image objects between two
            # MMGraphic or MMGraphic::IM objects
            $_->image->Clone();
        }
	=> from 'MMGraphicImage'
		=> via {
			# The Clone is not always necessary, but protects against
			# accidental cross-links of image objects between two
			# MMGraphic or MMGraphic::IM objects
            $_->image->image->Clone();
        };


coerce 'MMGraphicIMWrapper'
    => from 'Str'
        => via {
            # TODO: co-erce from URL using LWP/GET ?
            my $im = Image::Magick->new();
            $r = $im->Read( $_ );
            croak($r) if $r;
            MMGraphic::IM->new( image => $im );
            }
    => from 'IMImage'
        => via {
            MMGraphic::IM->new( image => $_ );
        }
    => from 'MMGraphicImage'
        => via {
            $_->image;
        };


coerce 'MMGraphicImage'
	=> from 'Str'
		=> via {
			# TODO: co-erce from URL using LWP/GET ?
			my $im = Image::Magick->new();
			$r = $im->Read( $_ );
			croak($r) if $r;
            MMGraphic->new( image => MMGraphic::IM->new( image => $im ) );
			}
	=> from 'IMImage'
		=> via {
            MMGraphic->new( image => MMGraphic::IM->new( image => $_ ) );
		}
    => from 'MMGraphicIMWrapper'
        => via {
            MMGraphic->new( image => $_ );
        };

1;
