#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/t/0-signature.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 1817 $ $DateTime: 2002/11/02 01:49:56 $

use strict;
print "1..1\n";

if (eval { require Socket; Socket::inet_aton('pgp.mit.edu') } and
    eval { require Module::Signature; 1 }
) {
    (Module::Signature::verify() == Module::Signature::SIGNATURE_OK())
	or print "not ";
    print "ok 1 # Valid signature\n";
}
else {
    warn "# Next time around, consider install Module::Signature,\n".
	 "# so you can verify the integrity of this distribution.\n";
    print "ok 1 # skip - Module::Signature not installed\n";
}

__END__
