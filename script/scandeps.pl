#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/script/scandeps.pl $ $Author: autrijus $
# $Revision: #6 $ $Change: 4445 $ $DateTime: 2003/02/27 12:09:56 $

$VERSION = '0.03';

use strict;
use Config;
use Getopt::Std;
use Module::ScanDeps;

my %opts;
getopts('BV', \%opts);

die "Usage: $0 [ -B ] [ -V ] file ...\n" unless @ARGV;

my $modtree = eval {
    require CPANPLUS::Backend;
    CPANPLUS::Backend->new->module_tree;
};

my (%map, %skip);
my $core    = $opts{B};
my $verbose = $opts{V};
my @files   = @ARGV;

while (<>) {
    next unless /^package\s+([\w:]+)/;
    $skip{$1}++;
}

my $map = scan_deps(
    files   => \@files,
    recurse => 1,
);


my $len = 0;
my @todo;
my (%seen, %dist, %core, %bin);

foreach my $key (sort keys %$map) {
    my $mod  = $map->{$key};
    my $name = $mod->{name} = _name($key);

    print "# $key [$mod->{type}]\n" if $verbose;

    if ($mod->{type} eq 'shared') {
	$key =~ s!auto/!!;
	$key =~ s!/[^/]+$!!;
	$key =~ s!/!::!;
	$bin{$key}++;
    }

    next unless $mod->{type} eq 'module';

    next if $skip{$name};

    if ($mod->{file} eq "$Config::Config{privlib}/$key"
	or $mod->{file} eq "$Config::Config{archlib}/$key") {
	next unless $core;

	$core{$name}++;
    }
    elsif (my $dist = $modtree->{$name}) {
	$seen{$name} = $dist{$dist->package}++;
    }

    $len = length($name) if $len < length($name);
    $mod->{used_by} ||= [];

    push @todo, $mod;
}

$len += 2;

warn "# Legend: [C]ore [X]ternal [S]ubmodule [?]NotOnCPAN\n";

foreach my $mod (sort {
    "@{$a->{used_by}}" cmp "@{$b->{used_by}}" or
    $a->{key} cmp $b->{key}
} @todo) {
    printf "%-${len}s => '0', # ", "'$mod->{name}'";
    my @base = map(_name($_), @{$mod->{used_by}});
    print $seen{$mod->{name}}	? 'S' : ' ';
    print $bin{$mod->{name}}	? 'X' : ' ';
    print $core{$mod->{name}}	? 'C' : ' ';
    print $modtree && !$modtree->{$mod->{name}} ? '?' : ' ';
    print " # ";
    print "@base" if @base;
    print "\n";
}

warn "No modules found!\n" unless @todo;

sub _name {
    my $str = shift;
    $str =~ s!/!::!g;
    $str =~ s!.pm$!!i;
    $str =~ s!^auto::(.+)::.*!$1!;
    return $str;
}

1;

__END__

=head1 NAME

scandeps.pl - Scan file prerequisites

=head1 SYNOPSIS

    % scandeps.pl *.pm		# Print PREREQ_PM section for *.pm
    % scandeps.pl -B *.pm	# Include core modules
    % scandeps.pl -V *.pm	# Show autoload/shared/data files

=head1 DESCRIPTION

F<scandeps.pl> is a simple-minded utility that prints out the
C<PREREQ_PM> section needed by modules.

If you have B<CPANPLUS> installed, modules that are part of an
earlier module's distribution with be denoted with C<S>; modules
without a distribution name on CPAN are marked with C<?>.

Also, if the C<-B> option is specified, module belongs to a perl
distribution on CPAN (and thus uninstallable by C<CPAN.pm> or
C<CPANPLUS.pm>) are marked with C<C>.

Finally, modules that has loadable shared object files (usually
needing a compiler to install) are marked with C<X>; with the
C<-V> flag, those files (and all other files found) will be listed
before the main output.

=head1 OPTIONS

=over 4

=item -B

Include core modules in the output and the recursive search list.

=item -V

Verbose mode: Output all files found during the process.

=head1 CAVEATS

All version numbers are set to C<0> in the output, despite explicit
C<use Module VERSION> statements.

=head1 SEE ALSO

L<Module::ScanDeps>, L<CPANPLUS::Backend>, L<PAR>

=head1 ACKNOWLEDGMENTS

Simon Cozens, for suggesting this script to be written.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
