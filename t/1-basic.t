#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 1832 $ $DateTime: 2002/11/02 15:37:15 $

use Test;
BEGIN { plan tests => 11 }

use Module::ScanDeps;
ok(1);

my $rv = scan_deps($0);

ok(exists $rv->{$_}) foreach qw(
    Carp.pm Config.pm	Exporter.pm Module/ScanDeps.pm	Test.pm
    base.pm constant.pm	fields.pm   strict.pm		vars.pm
);

__END__
