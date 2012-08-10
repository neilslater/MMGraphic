use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MMGraphic',
    AUTHOR              => q{Neil SLATER <slobo777@gmail.com>},
    VERSION_FROM        => 'lib/MMGraphic.pm',
    ABSTRACT_FROM       => 'lib/MMGraphic.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'MooseX::Method::Signatures' => 0,
        'List::AllUtils' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MMGraphic-*' },
);
