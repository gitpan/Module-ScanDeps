#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #1 $ $Change: 1817 $ $DateTime: 2002/11/02 01:49:56 $

use 5.006;
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
