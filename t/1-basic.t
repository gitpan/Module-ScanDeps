#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/t/1-basic.t $ $Author: autrijus $
# $Revision: #3 $ $Change: 1879 $ $DateTime: 2002/11/03 19:33:01 $

use Test;
BEGIN { plan tests => 10 }

use Module::ScanDeps;
ok(1);

my $rv = scan_deps($0);

ok(exists $rv->{$_}) foreach qw(
    Carp.pm Config.pm	Exporter.pm Test.pm
    base.pm constant.pm	strict.pm   vars.pm
    Module/ScanDeps.pm
);

__END__
