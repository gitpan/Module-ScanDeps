#!/usr/bin/perl
# $File: //member/autrijus/Module-ScanDeps/script/scandeps.pl $ $Author: autrijus $
# $Revision: #2 $ $Change: 3617 $ $DateTime: 2003/01/18 19:12:20 $

use Config;
use Module::ScanDeps;

my %map;
die "Usage: $0 [ -B ] file..." unless @ARGV;
my $bundle = shift if $ARGV[0] eq '-B';

my @files = @ARGV;
my %skip;
while (<>) {
    next unless /^package\s+([\w:]+)/;
    $skip{$1}++;
}

my $map = scan_deps(
    files   => \@files,
    recurse => 1,
);

print "PREREQ_PM => {\n";

my $len = 0;
my @todo;
foreach my $key (sort keys %$map) {
    my $mod = $map->{$key};
    next unless $mod->{type} eq 'module';
    next if $skip{_name($key)};
    next if !$bundle and ($mod->{file} eq "$Config::Config{privlib}/$key"
		       or $mod->{file} eq "$Config::Config{archlib}/$key");

    $len = length(_name($key))
	if $len < length(_name($key));

    push @todo, $mod;
}

$len += 2;

foreach my $mod (sort {
    "@{$a->{used_by}}" cmp "@{$b->{used_by}}" or
    $a->{key} cmp $b->{key}
} @todo) {
    printf "\t%-${len}s => '0',", "'"._name($mod->{key})."'";
    my @base = map(_name($_), @{$mod->{used_by}});
    print " # @base" if @base;
    print "\n";
}

print "}\n";

sub _name {
    my $str = shift;
    $str =~ s!/!::!g;
    $str =~ s!.pm$!!i;
    return $str;
}

1;

__END__

=head1 NAME

scandeps.pl - Scan file prerequisites

=head1 SYNOPSIS

    % scandeps.pl *.pm		# Print PREREQ_PM section for *.pm
    % scandeps.pl -B *.pm	# Include core modules

=head1 DESCRIPTION

F<scandeps.pl> is a simple-minded utility that prints out the
C<PREREQ_PM> section needed by modules.

=head1 OPTIONS

=over 4

=item -B

Include core modules in the output and the recursive search list.

=head1 CAVEATS

All version numbers are set to C<0>, despite explicit
C<use Module VERSION> statements.

=head1 SEE ALSO

L<Module::ScanDeps>, L<PAR>

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
