#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #4 $ $Change: 7579 $ $DateTime: 2003/08/17 18:55:41 $

use 5.001;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Recursively scan Perl programs for dependencies',
    NAME		=> 'Module::ScanDeps',
    VERSION_FROM	=> 'lib/Module/ScanDeps.pm', 
    DISTNAME		=> 'Module-ScanDeps',
    BINARY_LOCATION	=> 'x86/ScanDeps.tar.gz',
    EXE_FILES		=> [ 'script/scandeps.pl' ],

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);
