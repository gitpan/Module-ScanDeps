# $File: //member/autrijus/Module-ScanDeps/ScanDeps.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1817 $ $DateTime: 2002/11/02 01:49:56 $

package Module::ScanDeps;
use 5.006;
our $VERSION = '0.01';

use strict;
use warnings;
use Config ();
use constant dl_ext => ".$Config::Config{dlext}";

=head1 NAME

Module::ScanDeps - Recursively scan Perl programs for dependencies

=head1 VERSION

This document describes version 0.01 of Module::ScanDeps, released
November 2, 2002.

=head1 SYNOPSIS

    use Module::ScanDeps;

    # standard usage
    my $hash_ref = Module::ScanDeps::scan_deps(
	files	=> [ ... ],
	recurse	=> 1,
    );

    # shorthand; assume recurse == 1
    my $hash_ref = Module::ScanDeps::scan_deps( 'a.pl', 'b.pl' );

=head1 DESCRIPTION

This module scans potential found used by perl programs,
and returns a hash reference; its keys are the module names
as appears in C<%INC> (e.g. C<Test/More.pm>), with the value
pointing to the actual file name on disk.

Nothing is exported by default.

=head1 CAVEATS

This module is oblivious about the B<BSDPAN> hack on FreeBSD,
by removing it from C<@INC> altogether.

No source code are actually compiled by this module, so the
heuristic is likely to be not 100% accurate.  Patches welcome!

=cut

my %Preload = (
    'LWP/UserAgent.pm'	    => [qw(
	URI/URL.pm URI/http.pm LWP/Protocol/http.pm
    )],
    'Term/ReadLine.pm'	    => [qw(
	Term/ReadLine/readline.pm Term/ReadLine/Perl.pm
    )],
    'File/Basename.pm'	    => [qw( re.pm )],
    'Win32/EventLog.pm'	    => [qw( Win32/IPC.pm )],
    'Net/FTP.pm'	    => [qw( Net/FTP/I.pm )],
    'Win32/TieRegistry.pm'  => [qw( Win32API/Registry.pm )],
    'Tk.pm'		    => [qw( Tk/FileSelect.pm )],
    'Tk/Toplevel.pm'	    => [qw( Tk/Wm.pm )],
    'IO/Socket.pm'	    => [qw( IO/Socket/UNIX.pm )],
    'Tk/ColorEditor.pm'	    => [qw( Tk/ColorEdit.xpm )],
    'Tk/FBox.pm'	    => [qw( Tk/folder.xpm Tk/file.xmp )],
    'Tk/Balloon.pm'	    => [qw( Tk/balArrow.xbm )],
    'Tk/BrowseEntry.pm'	    => [qw( Tk/cbxarrow.xbm )],
    'File/Spec.pm'	    => [
	($^O eq 'MSWin32') ? qw( File/Spec/Win32.pm )
			   : qw( File/Spec/Unix.pm )
    ],
);

sub scan_deps {
    my %args = (
	($_[0] =~ /^(?:files|recurse|rv|seen)$/)
	    ? @_ : ( files => [ @_ ], recurse => 1 )
    );
    my ($files, $recurse, $rv, $seen) = @args{qw/files recurse rv seen/};

    $rv ||= {}; $seen ||= {};

    foreach my $file (@{$files}) {
	next if $seen->{$file}++;
	open my $fh, $file or die "Cannot open $file: $!";

	LINE: foreach (<$fh>) {
	    chomp;
	    foreach ( _scan_line($_) ) {
		last LINE if /^__END__$/;

		if (/^__POD__$/) {
		    while (<$fh>) { last if (/^=cut/) }
		    next LINE;
		}

		next if /\.ph$/i;

		$_ = 'CGI/Apache.pm' if /^Apache(?:\.pm)$/;
		_add_deps($rv, @{$Preload{$_}}) if exists $Preload{$_};
		_add_deps($rv, $_);
	    }
	}
	close $fh;
    }

    while ($recurse) {
	my $count = keys %$rv;
	scan_deps(
	    files   => [ values %$rv ],
	    rv	    => $rv,
	    seen    => $seen,
	    recurse => 0,
	) or ($args{_deep} and return);
	last if $count == keys %$rv;
    }

    return $rv;
}

sub _scan_line {
    my $line = shift;
    my %found;

    return '__END__' if $line =~ /^__(?:END|DATA)__$/;
    return '__POD__' if $line =~ /^=[\w]+/;

    s/\s*#.*$//; s/[\\\/]+/\//g;

    foreach (split(/;/, $line)) {
	return if /^\s*(use|require)\s+[\d\._]+/;

	if (my $libs = /\s*use\s+lib\s+(.+)/) {
	    push @INC, (grep /\w/, split(/["';]/, $libs));
	    next;
	}

	my $module = _scan_chunk($_) or next;
	$module =~ s/::/\//g;
	$module .= ".pm" unless $module =~ /\.pm/i;

	$found{$module}++;
    }

    return sort keys %found;
}

sub _scan_chunk {
    local $_ = shift;
    return $1 if /\b(?:use|require)\s+([\w:\.\-\\\/\"\']*)/;
    return $1 if /\b(?:use|require)\s+\(\s*([\w:\.\-\\\/\"\']*)\s*\)/;

    if (s/\beval\s+\"([^\"]+)\"/$1/ or s/\beval\s*\(\s*\"([^\"]+)\"\s*\)/$1/) {
	return $1 if /\b(?:use|require)\s+([\w:\.\-\\\/\"\']*)/;
    }

    return if /^[\d\._]+$/ or /^'.*[^']$/ or /^".*[^"]$/;
    return $1 if /\b(?:do|require)\s+[^"]*"(.*?)"/;
    return $1 if /\b(?:do|require)\s+[^']*'(.*?)'/;
}

sub _add_deps {
    my $rv = shift;

    foreach my $module (@_) {
	next if exists $rv->{$module};

	my $file = _find_inc($module) or next;
	$rv->{$module} = $file;

	if ($module =~ /(.*?([^\/]*))\.pm$/i) {
	    my ($path, $basename) = ($1, $2);

	    # shared objects
	    if ($basename) {
		my $dl_name = "auto/$path/$basename" . dl_ext();
		my $dl_file = _find_inc($dl_name) ||
			      _find_inc($basename . dl_ext());
		$rv->{$dl_name} = $dl_file if defined $dl_file;
	    }

	    # autosplit
	    my $autosplit_dir = _find_inc("auto/$path/autosplit.ix") or next;
	    $autosplit_dir =~ s/autosplit\.ix$//;

	    opendir (my $DIR, $autosplit_dir) or next;
	    $rv->{"auto/$path/$_"} = "$autosplit_dir/$_"
		foreach grep /\.(?:ix|al)$/i, readdir $DIR;
	    closedir $DIR;
        }
    }
}

sub _find_inc {
    my $file = shift;
    return $file if -f $file;

    foreach my $dir (grep !/\bBSDPAN\b/, @INC) {
	return "$dir/$file" if -f "$dir/$file";
    }

    return;
}

1;

__END__

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Part of heuristics are taken from F<perl2exe-scan.pl>
by Indy Singh E<lt>indy@indigostar.comE<gt>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
