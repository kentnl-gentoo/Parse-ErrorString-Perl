
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Parse error messages from the perl interpreter',
  'AUTHOR' => 'Petar Shangov, C<< <pshangov at yahoo.com> >>, Gabor Szabo L<http://szabgab.com/>, Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::Differences' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Parse-ErrorString-Perl',
  'EXE_FILES' => [
    'bin/check_perldiag'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Parse::ErrorString::Perl',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::XSAccessor' => '0',
    'File::Basename' => '0',
    'File::Spec' => '0',
    'Pod::Find' => '0',
    'Pod::POM' => '0'
  },
  'VERSION' => '0.14',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



