# $File: //member/autrijus/Module-ScanDeps/lib/Module/ScanDeps/DataFeed.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 9510 $ $DateTime: 2003/12/31 10:42:43 $ vim: expandtab shiftwidth=4

package Module::ScanDeps::DataFeed;
$Module::ScanDeps::DataFeed::VERSION = '0.01';

=head1 NAME

Module::ScanDeps::DataFeed - Runtime dependency scanning helper

=head1 SYNOPSIS

(internal use only)

=head1 DESCRIPTION

No user-serviceable parts inside.

=cut

my $_filename;

sub import {
    my ($pkg, $filename) = @_;
    $_filename = $filename;

    my $fname = __PACKAGE__;
    $fname =~ s{::}{/}g;
    delete $INC{"$fname.pm"} unless $Module::ScanDeps::DataFeed::Loaded++;
}

END {
    defined $_filename or return;

    my %inc = %INC;
    my @inc = @INC;

    require Cwd;
    require DynaLoader;

    open(FH, "> $_filename") or die "Couldn't open $_filename\n";
    print FH '%inchash = (' . "\n\t";
    print FH join(
        ',' => map("\n\t'$_' => '" . Cwd::abs_path($inc{$_}) . "'", keys(%inc))
    );
    print FH "\n);\n";

    print FH '@incarray = (' . "\n\t";
    print FH join(',', map("\n\t'$_'", @inc));
    print FH "\n);\n";

    my @dl_bs = @DynaLoader::dl_shared_objects;
    s/(\.so|\.dll)$/\.bs/ for @dl_bs;
    @dl_bs = grep(-e $_, @dl_bs);

    print FH '@dl_shared_objects = (' . "\n\t";
    print FH join(
        ',',=> map("\n\t'$_'", @DynaLoader::dl_shared_objects, @dl_bs)
    );
    print FH "\n);\n";
    close FH;
}

1;

=head1 SEE ALSO

L<Module::ScanDeps>

=head1 AUTHORS

Edward S. Peschko E<lt>esp5@pge.comE<gt>,
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

L<http://par.perl.org/> is the official website for this module.  You
can write to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty
mail to E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-Module-ScanDeps@rt.cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2004 by Edward S. Peschko E<lt>esp5@pge.comE<gt>,
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
