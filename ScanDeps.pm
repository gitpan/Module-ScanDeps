# $File: //member/autrijus/Module-ScanDeps/ScanDeps.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 1833 $ $DateTime: 2002/11/02 15:38:42 $

package Module::ScanDeps;
use vars qw/$VERSION @EXPORT @EXPORT_OK/;

$VERSION    = '0.02';
@EXPORT	    = ('scan_deps');
@EXPORT_OK  = ('scan_line', 'scan_chunk', 'add_deps');

use strict;
use Exporter;
use base 'Exporter';
use Config ();
use constant dl_ext => ".$Config::Config{dlext}";

=head1 NAME

Module::ScanDeps - Recursively scan Perl programs for dependencies

=head1 VERSION

This document describes version 0.02 of Module::ScanDeps, released
November 2, 2002.

=head1 SYNOPSIS

    use Module::ScanDeps;

    # standard usage
    my $hash_ref = scan_deps(
	files	=> [ 'a.pl', 'b.pl' ],
	recurse	=> 1,
    );

    # shorthand; assume recurse == 1
    my $hash_ref = scan_deps( 'a.pl', 'b.pl' );

=head1 DESCRIPTION

This module scans potential modules used by perl programs, and returns a
hash reference; its keys are the module names as appears in C<%INC>
(e.g. C<Test/More.pm>), with the value pointing to the actual file name
on disk.

One function, C<scan_deps>, is exported by default.  Three other
functions (C<scan_line>, C<scan_chunk>, C<add_deps>) are exported upon
request.

=head2 B<scan_deps>

    $rv_ref = scan_deps(
	files	=> \@files, recurse	=> $bool,
	rv	=> \%rv,    skip	=> \%skip,
    );
    $rv_ref = scan_deps(@files); # shorthand, with recurse => 1

This function scans each file in C<@files>, registering their
dependencies into C<%rv>, and returns a reference to the updated C<%rv>.
The meaning of keys and values are explained previously.

If the C<recurse> flag is true, C<scan_deps> will call itself
recursively, to perform a breadth-first search on text files (as
recognized by -T) found in C<%rv>.

If the C<\%skip> is specified, files that exists as its keys are
skipped.  This is used internally to avoid infinite recursion.

=head2 B<scan_line>

    @modules = scan_line($line);

Splits a line into chunks (currently with the semicolon characters), and
return the union of C<scan_chunk> calls of them.

If the line is C<__END__> or C<__DATA__>, a single C<__END__> element is
returned to signify the end of the program.

Similarly, it returns a single C<__POD__> if the line matches C</^=\w/>;
the caller is responsible for skipping appropriate number of lines
until C<=cut>, before calling C<scan_line> again.

=head2 B<scan_chunk>

    $module = scan_chunk($chunk);

Apply various heuristics to C<$chunk> to find and return the module name
it contains, or C<undef> if nothing were found.

=head2 B<add_deps>

    $rv_ref = add_deps( rv => \%rv, modules => \@modules );
    $rv_ref = add_deps( @modules ); # shorthand, without rv

Resolves a list of module names to its actual on-disk location, by
finding in C<@INC>; modules that cannot be found are skipped.

This function populates the C<%rv> hash with module/filename pairs, and
returns a reference to it.

=head1 CAVEATS

This module is oblivious about the B<BSDPAN> hack on FreeBSD -- the
additional directory is removed from C<@INC> altogether.

No source code are actually compiled by this module, so the heuristic is
not likely to be 100% accurate.  Patches welcome!

=cut

# Pre-loaded module dependencies {{{
my %Preload = (
    'File/Basename.pm'	    => [qw( re.pm )],
    'File/Spec.pm'	    => [ ($^O eq 'MSWin32') ? qw(
	File/Spec/Win32.pm
    ) : qw(
	File/Spec/Unix.pm
    )],
    'IO/Socket.pm'	    => [qw( IO/Socket/UNIX.pm )],
    'LWP/UserAgent.pm'	    => [qw(
	URI/URL.pm
	URI/http.pm
	LWP/Protocol/http.pm
    )],
    'Net/FTP.pm'	    => [qw( Net/FTP/I.pm )],
    'Term/ReadLine.pm'	    => [qw(
	Term/ReadLine/readline.pm
	Term/ReadLine/Perl.pm
    )],
    'Tk.pm'		    => [qw( Tk/FileSelect.pm )],
    'Tk/Balloon.pm'	    => [qw( Tk/balArrow.xbm )],
    'Tk/BrowseEntry.pm'	    => [qw( Tk/cbxarrow.xbm )],
    'Tk/ColorEditor.pm'	    => [qw( Tk/ColorEdit.xpm )],
    'Tk/FBox.pm'	    => [qw( Tk/folder.xpm Tk/file.xmp )],
    'Tk/Toplevel.pm'	    => [qw( Tk/Wm.pm )],
    'Win32/EventLog.pm'	    => [qw( Win32/IPC.pm )],
    'Win32/TieRegistry.pm'  => [qw( Win32API/Registry.pm )],
);
# }}}

sub scan_deps {
    my %args = (
	(@_ and $_[0] =~ /^(?:files|recurse|rv|skip)$/)
	    ? @_ : ( files => [ @_ ], recurse => 1 )
    );
    my ($files, $recurse, $rv, $skip) = @args{qw/files recurse rv skip/};

    $rv ||= {}; $skip ||= {};

    foreach my $file (@{$files}) {
	next if $skip->{$file}++;

	local *FH;
	open FH, $file or die "Cannot open $file: $!";

        # Line-by-line scanning {{{
	LINE: while (<FH>) {
	    chomp;
	    foreach ( scan_line($_) ) {
		last LINE if /^__END__$/;

		if (/^__POD__$/) {
		    while (<FH>) { last if (/^=cut/) }
		    next LINE;
		}

		next if /\.ph$/i;

		$_ = 'CGI/Apache.pm' if /^Apache(?:\.pm)$/;

		add_deps( rv => $rv, modules => [ $_ ] );
		add_deps( rv => $rv, modules => $Preload{$_} )
		    if exists $Preload{$_};
	    }
	}
	close FH;
        # }}}
    }

    # Top-level recursion handling {{{
    while ($recurse) {
	my $count = keys %$rv;
	scan_deps(
	    files   => [ sort grep -T, values %$rv ],
	    rv	    => $rv,
	    skip    => $skip,
	    recurse => 0,
	) or ($args{_deep} and return);
	last if $count == keys %$rv;
    }
    # }}}

    return $rv;
}

sub scan_line {
    my $line = shift;
    my %found;

    return '__END__' if $line =~ /^__(?:END|DATA)__$/;
    return '__POD__' if $line =~ /^=\w/;

    s/\s*#.*$//; s/[\\\/]+/\//g;

    foreach (split(/;/, $line)) {
	return if /^\s*(use|require)\s+[\d\._]+/;

	if (my $libs = /\s*use\s+lib\s+(.+)/) {
	    push @INC, (grep /\w/, split(/["';]/, $libs));
	    next;
	}

	my $module = scan_chunk($_) or next;
	$found{$module}++;
    }

    return sort keys %found;
}

sub scan_chunk {
    my $chunk = shift;

    # Module name extraction heuristics {{{
    my $module = eval {
	$_ = $chunk;
	return $1 if /\b(?:use|require)\s+([\w:\.\-\\\/\"\']*)/;
	return $1 if /\b(?:use|require)\s+\(\s*([\w:\.\-\\\/\"\']*)\s*\)/;

	if (s/\beval\s+\"([^\"]+)\"/$1/ or s/\beval\s*\(\s*\"([^\"]+)\"\s*\)/$1/) {
	    return $1 if /\b(?:use|require)\s+([\w:\.\-\\\/\"\']*)/;
	}

	return if /^[\d\._]+$/ or /^'.*[^']$/ or /^".*[^"]$/;
	return $1 if /\b(?:do|require)\s+[^"]*"(.*?)"/;
	return $1 if /\b(?:do|require)\s+[^']*'(.*?)'/;
	return;
    };
    # }}}

    return unless defined($module) and $module =~ /^\w/;

    $module =~ s/\W+$//;
    $module =~ s/::/\//g;
    $module .= ".pm" unless $module =~ /\.pm/i;
    return $module;
}

sub add_deps {
    my %args = (
	(@_ and $_[0] =~ /^(?:modules|rv)$/)
	    ? @_ : ( rv => ( ref($_[0]) ? shift(@_) : undef ), modules => [ @_ ] )
    );
    my $rv = $args{rv} || {};

    foreach my $module (@{$args{modules}}) {
	next if exists $rv->{$module};

	my $file = _find_in_inc($module) or next;
	$rv->{$module} = $file;

	if ($module =~ /(.*?([^\/]*))\.pm$/i) {
	    my ($path, $basename) = ($1, $2);

            # Shared objects {{{
	    if (defined $basename) {
		my $dl_name = "auto/$path/$basename" . dl_ext();
		my $dl_file = _find_in_inc($dl_name) ||
			      _find_in_inc($basename . dl_ext());
		$rv->{$dl_name} = $dl_file if defined $dl_file;
	    }
            # }}}
            # Autosplit files {{{
	    my $autosplit_dir = _find_in_inc("auto/$path/autosplit.ix") or next;
	    $autosplit_dir =~ s/\/autosplit\.ix$//;

	    local *DIR;
	    opendir(DIR, $autosplit_dir) or next;
	    $rv->{"auto/$path/$_"} = "$autosplit_dir/$_"
		foreach grep /\.(?:ix|al)$/i, readdir(DIR);
	    closedir DIR;
            # }}}
        }
    }

    return $rv;
}

sub _find_in_inc {
    my $file = shift;

    # absolute file names
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
