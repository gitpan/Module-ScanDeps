#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #3 $ $Change: 3617 $ $DateTime: 2003/01/18 19:12:20 $

use 5.001;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Recursively scan Perl programs for dependencies',
    NAME		=> 'Module::ScanDeps',
    VERSION_FROM	=> 'ScanDeps.pm', 
    DISTNAME		=> 'Module-ScanDeps',
    BINARY_LOCATION	=> 'x86/ScanDeps.tar.gz',
    EXE_FILES		=> [ 'script/scandeps.pl' ],

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);
