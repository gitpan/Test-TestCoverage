package Test::TestCoverage;

use strict;
use warnings;
use Devel::Symdump;
use Test::Builder;
use B;
use Hook::LexWrap;
use base qw(Exporter);

our @EXPORT = qw(
                 test_coverage 
                 ok_test_coverage
                 reset_test_coverage
                 reset_all_test_coverage
                );
our $VERSION = '0.01';

my $self    = {};
my $test    = Test::Builder->new();
my $invokes = {};


sub test_coverage{
    my ($package) = @_;
    return unless defined $package;
    _get_subroutines($package);
    for my $subref(@{$self->{subs}->{$package}}){
        my $sub      = $subref->[0];
        my $sub_with = $package . '::' . $sub;
        unless(exists $invokes->{$package}->{$sub}){
            $invokes->{$package}->{$sub} = 0;
        }
        
        Hook::LexWrap::wrap($sub_with, 
            pre => sub{
                $invokes->{$package}->{$sub}++; 
            }
        );
    }
        
    1;
}

sub ok_test_coverage{
    my ($package,$msg) = @_;
    
    unless(exists $invokes->{$package}){
        warn $package.' was not tested';
        return;
    }
    
    my $bool_msg = defined $msg ? 1 : 0;
    my $title    = 'Test test-coverage ';
    my $missing;
    
    my $bool_coverage = 1;
    for my $sub(map{$_->[0]}@{$self->{subs}->{$package}}){
        if(!exists $invokes->{$package}->{$sub} or $invokes->{$package}->{$sub} == 0){
            $missing = defined $missing && !$bool_msg ? $missing . $sub . ' ' : $sub . ' ';
            $bool_coverage = 0;
        }
    }
    
    if(!$bool_msg){
        $msg  = $title;
        $msg .= $missing.' are missing' if(defined $missing);
    }
    
    $test->cmp_ok($bool_coverage,"==",1,$msg);
    1;
}

sub reset_test_coverage{
    my ($self,$pkg) = @_;
    for my $key(keys %{$invokes->{$pkg}}){
        $invokes->{$pkg}->{$key} = 0;
    }
}

sub reset_all_test_coverage{
    my ($self) = @_;
    for my $pkg(keys %{$invokes}){
        $self->reset_test_coverage($pkg);
    }
}

sub _get_subroutines{
    my ($pkg,$test) = @_;
        
    eval qq{ require $pkg };
    print STDERR $@ if $@;
    return if $@;
    
    $test ||= $pkg;    

    my $symdump = Devel::Symdump->new($pkg);

    my @symbols;
    for my $func ($symdump->functions ) {
        my $owner = _get_sub(\&{$func});
        $owner =~ s/^\*(.*)::.*?$/$1/;
        next if $owner ne $test;

        # check if it's on the whitelist
        $func =~ s/${pkg}:://;

        push @symbols, [$func,$owner] unless $func =~ /^_/;
    }
    
    $self->{subs}->{$pkg} = \@symbols;
    
    1;
}

sub _get_sub {
    my ($svref) = @_;
    my $b_cv = B::svref_2object($svref);
    no strict 'refs';
    return *{ $b_cv->GV->STASH->NAME . "::" . $b_cv->GV->NAME };
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::TestCoverage - Test if your test covers all 'public' methods of the package

=head1 SYNOPSIS

  use Test::TestCoverage;
  
  test_coverage('My::Module');
  
  # run some test code
  
  ok_test_coverage('My::Module');

=head1 DESCRIPTION

If you're writing a new module

=head1 METHODS

=head2 test_coverage $module

Tells C<Test::TestCoverage> for what module the coverage should be tested

=head3 ok_test_coverage $module

Checks if all "public" methods of C<$module> were called in the testscript

=head3 reset_test_coverage $module

Resets the counter for all method invokations of C<$module>'s methods.

=head3 reset_all_test_coverage

Resets the counter for all methods of all modules that were registerd via
C<test_coverage>.

=head1 EXPORT

C<test_coverage>, C<ok_test_coverage>, C<reset_test_coverage>,
C<reset_all_test_coverage>

=head1 SEE ALSO

L<Test::SubCalls>, L<Test::Builder>

=head1 BUGS / TODO

There are a lot of things to do. If you experience any problems please contact
me.

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
