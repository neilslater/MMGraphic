MMGraphic
==========

MMGraphic provides some useful high-level graphics commands based on 
Image::Magick. It does not "wrap" Image::Magic, but does make it easier
to do one or two things.

INSTALL IMAGE MAGICK BEFORE INSTALLING MMGraphic
================================================

MMGraphic's make file cannot follow the dependency on Image::Magick 
automatically. For instructions on how to install the image magick library
including Perl bindings for your OS, see:

	http://www.imagemagick.org/

INSTALLATION
============

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION
=========================

After installing, you can find documentation for this module with the
perldoc command.

    perldoc MMGraphic

LICENSE AND COPYRIGHT
======================

Copyright (C) 2011 Neil SLATER

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
