#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 1830 $ $DateTime: 2002/11/02 15:36:29 $

use 5.001;
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Recursively scan Perl programs for dependencies',
    NAME		=> 'Module::ScanDeps',
    VERSION_FROM	=> 'ScanDeps.pm', 
    DISTNAME		=> 'Module-ScanDeps',
    BINARY_LOCATION	=> 'x86/ScanDeps.tar.gz',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);
