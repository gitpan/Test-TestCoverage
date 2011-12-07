use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Test::TestCoverage',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Test/TestCoverage.pm',
  ABSTRACT_FROM => 'lib/Test/TestCoverage.pm',
  PREREQ_PM => {
    'ExtUtils::Manifest'  => 0,
    'File::Spec'          => 0,
    'Pod::Parser'         => 0,
    'Test::More'          => '0.47',
    'Test::UseAllModules' => '0.10',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
