#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #5 $ $Change: 8459 $ $DateTime: 2003/10/17 22:34:31 $

use 5.001;
use inc::Module::Install;

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Recursively scan Perl programs for dependencies',
    NAME		=> 'Module::ScanDeps',
    VERSION_FROM	=> 'lib/Module/ScanDeps.pm', 
    DISTNAME		=> 'Module-ScanDeps',
    EXE_FILES		=> [ 'script/scandeps.pl' ],
    SIGN		=> 1,
);
