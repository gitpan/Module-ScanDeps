#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #7 $ $Change: 9631 $ $DateTime: 2004/01/08 11:19:45 $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Module::ScanDeps',
    ABSTRACT		=> 'Recursively scan Perl programs for dependencies',
    AUTHOR		=> 'Autrijus Tang <autrijus@autrijus.org>',
    VERSION_FROM	=> 'lib/Module/ScanDeps.pm',
    EXE_FILES		=> [ 'script/scandeps.pl' ],
    ((ExtUtils::MakeMaker->VERSION >= 6.21) ? (SIGN => 1) : ()),
);

__END__

use inc::Module::Install;

name		('Module-ScanDeps');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Recursively scan Perl programs for dependencies');
version_from	('lib/Module/ScanDeps.pm');
install_script	('script/scandeps.pl');
license		('perl');
sign		(1);

&WriteAll;
