#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/Makefile.PL $ $Author: autrijus $
# $Revision: #6 $ $Change: 9371 $ $DateTime: 2003/12/21 01:14:18 $

use inc::Module::Install;

name		('Module-ScanDeps');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Recursively scan Perl programs for dependencies');
version_from	('lib/Module/ScanDeps.pm');
install_script	('script/scandeps.pl');
license		('perl');
sign		(1);

&WriteAll;
