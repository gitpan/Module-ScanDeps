#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

use Test::More tests => 6;

##############################################################
# Tests compilation of Module::ScanDeps
##############################################################
BEGIN { use_ok( 'Module::ScanDeps', qw(path_to_inc_name) ); }

my $name;
my $basepath;
my $warn = 1;

# Absolute path tests
$basepath = cwd().'/t/data/check_path_to_inc_name/';
$name = 'Some.pm';
is(path_to_inc_name($basepath.$name, $warn), $name, "$name correctly returned by path_to_inc_name($basepath$name)");
$name = 'Scoped/Package.pm';
is(path_to_inc_name($basepath.$name, $warn), $name, "$name correctly returned by path_to_inc_name($basepath$name)");

# Relative path tests
$basepath = 't/data/check_path_to_inc_name/';
$name = 'Some.pm';
is(path_to_inc_name($basepath.$name, $warn), $name, "$name correctly returned by path_to_inc_name($basepath$name)");
$name = 'Scoped/Package.pm';
is(path_to_inc_name($basepath.$name, $warn), $name, "$name correctly returned by path_to_inc_name($basepath$name)");

# script test
$basepath = 't/data/check_path_to_inc_name/';
$name = 'use_scoped_package.pl';
is(path_to_inc_name($basepath.$name, $warn), $name, "$name correctly returned by path_to_inc_name($basepath$name)");

__END__