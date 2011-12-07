package Test::TestCoverage;

use strict;
use warnings;
use Test::More;
use base 'Exporter';
use ExtUtils::Manifest qw/maniread/;
use File::Spec;

our $VERSION = '0.01';

our @EXPORT = qw/test_coverage_ok/;

my $RULE = qr{^x?t/(.+)\.(?:t|pm)\s*$};

sub import {
  shift->export_to_level(1);
  shift if @_ && $_[0] eq 'under';
  if (@_) {
    my @dirs = ('t', 'xt', @_);
    my %seen;
    @dirs = grep { !$seen{$_}++ } map { s|/+$||; $_ } @dirs;
    $RULE = '^(?:' . (join '|', @dirs) . ')/(.+)\.(?:t|pm)\s*$';
  }
}

sub _get_testfile_list {
  shift if @_ && $_[0] eq 'except';
  my @exceptions = @_;
  my @files;

  my $manifest = maniread();

READ:
  foreach my $file (keys %{ $manifest }) {
    if ($file =~ /$RULE/) {
      foreach my $rule (@exceptions) {
        next READ if $file eq $rule || $file =~ /$rule/;
      }

      push @files, $file;
    }
  }
  return @files;
}

sub _planned {
  if ($Test::More::VERSION >= 2) {
    Test::More->builder->_plan_handled;
  } else {
    Test::More->builder->{Have_Plan};
  }
}

sub test_coverage_ok {
  unless (-f 'MANIFEST') {
    plan skip_all => 'no MANIFEST' unless _planned();
    return;
  }

  my @files = _get_testfile_list(@_);

  unless (@files) {
    plan skip_all => 'no test files are found' unless _planned();
    return;
  }

  plan tests => scalar @files unless _planned();

  my @failed;
  foreach my $file (@files) {
    my @declared = _find_declared_tests($file);
    if (!@declared) {
       SKIP: { skip "$file has no declared tests", 1; fail; }
       next;
    }
    my $content = do { local $/; open my $fh, '<', $file; <$fh> };
    my @not_found;
    for (@declared) {
      # XXX: should use Class::Inspector for better testing?
      if ($content !~ /\bsub\s+$_\b/s) {
        push @not_found, $_;
      }
    }
    if (@not_found) {
      fail "$file has unimplemented tests: " . (join ',', @not_found);
    }
    else {
      pass $file;
    }
  }
}

sub _find_declared_tests {
  my $file = shift;

  my $parser = Test::TestCoverage::Parser->new(TESTS => []);
  $parser->parse_from_file($file, File::Spec->devnull);
  return @{ $parser->{TESTS} || [] };
}

package #
  Test::TestCoverage::Parser;

use strict;
use warnings;
use base 'Pod::Parser';

sub command {
  my ($self, $command, $text, $line_num, $pod) = @_;
  if ($command eq 'head1') {
    $self->{DECLARING} = ($text =~ /\btests?\b/i) ? 1 : 0;
    return;
  }
  return unless $self->{DECLARING};
  if ($command =~ /^(head[234]|item)$/) {
    my ($test_name) = $text =~ /^(\w+)/;
    push @{ $self->{TESTS} }, $test_name;
  }
}

1;

__END__

=head1 NAME

Test::TestCoverage - see if all the unit tests are actually written

=head1 SYNOPSIS

  # basic usage
  use strict;
  use Test::TestCoverage;
  test_coverage_ok();

  # if you also want to test files under lib/ 
  use strict;
  use Test::TestCoverage under qw(lib/);
  test_coverage_ok();

  # if you don't want to test some specific files
  use strict;
  use Test::TestCoverage;
  test_coverage_ok except => qw(
    t/todo/test.t
    t/obsolete/.+ # you can use regex
  )

=head1 DESCRIPTION

Say you are a project manager. You know what you have promised to deliver, and you know what should be tested. However, you are too busy to write all the tests by yourself. Then, why don't you write down what tests to be written as POD, and wait until someone implements all the details later?

As of this writing, this module slurps all the known (i.e. MANIFESTed) .t and .pm files under t/ (and xt/ if exists) directory by default, and if it finds C<head1> section(s) titled like C<Test(s)>, parses the following sections to find the names of the tests to be written, and then check the file again to see if the tests are actually implemented. If all the declared tests exist (as subroutines/methods), that's fine. If not, the test fails and you'll be informed what to write before you release.

In short, L<Test::TestCoverage> is to write enough tests in the sense that L<Test::Pod::Coverage> is to write enough pods.

Hope this helps.

=head1 EXPORTED FUNCTION

=head2 test_coverage_ok

Tests if all the tests files have the (unit) tests your declared in the POD.

=head1 SEE ALSO

L<Test::UseAllModules>, L<Test::Pod::Coverage>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
