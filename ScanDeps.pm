# $File: //member/autrijus/Module-ScanDeps/ScanDeps.pm $ $Author: autrijus $
# $Revision: #6 $ $Change: 1910 $ $DateTime: 2002/11/04 11:43:36 $

package Module::ScanDeps;
use vars qw/$VERSION @EXPORT @EXPORT_OK/;

$VERSION    = '0.10';
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

This document describes version 0.10 of Module::ScanDeps, released
November 4, 2002.

=head1 SYNOPSIS

    use Module::ScanDeps;

    # standard usage
    my $hash_ref = scan_deps(
	files	=> [ 'a.pl', 'b.pl' ],
	recurse	=> 1,
    );

    # shorthand; assume recurse == 1
    my $hash_ref = scan_deps( 'a.pl', 'b.pl' );

    # App::Packer::Frontend compatible interface
    # see App::Packer::Frontend for the structure returned by get_files
    my $scan = Module::ScanDeps->new;
    $scan->set_file( 'a.pl' );
    $scan->set_options( add_modules => [ 'Test::More' ] );
    $scan->calculate_info;
    my $files = $scan->get_files;

=head1 DESCRIPTION

This module scans potential modules used by perl programs, and returns a
hash reference; its keys are the module names as appears in C<%INC>
(e.g. C<Test/More.pm>); the values are hash references with this structure:

    {
	file	=> '/usr/local/lib/perl5/5.8.0/Test/More.pm',
	key	=> 'Test/More.pm',
	type	=> 'module',	# or 'autoload', 'data', 'shared'
	used_by	=> [ 'Test/Simple.pm', ... ],
    }

One function, C<scan_deps>, is exported by default.  Three other
functions (C<scan_line>, C<scan_chunk>, C<add_deps>) are exported upon
request.

Users of B<App::Packer> may also use this module as the dependency-checking
frontend, by tweaking their F<p2e.pl> like below:

    use Module::ScanDeps;
    ...
    my $packer = App::Packer->new( frontend => 'Module::ScanDeps' );
    ...

Please see L<App::Packer::Frontend> for detailed explanation on
the structure returned by C<get_files>.

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
    'ExtUtils/MakeMaker.pm'    => [qw(
	ExtUtils/MM_Any.pm
	ExtUtils/MM_BeOS.pm
	ExtUtils/MM_Cygwin.pm
	ExtUtils/MM_DOS.pm
	ExtUtils/MM_MacOS.pm
	ExtUtils/MM_NW5.pm
	ExtUtils/MM_OS2.pm
	ExtUtils/MM_UWIN.pm
	ExtUtils/MM_Unix.pm
	ExtUtils/MM_VMS.pm
	ExtUtils/MM_Win32.pm
	ExtUtils/MM_Win95.pm
    )],
    'File/Basename.pm'		    => [qw( re.pm )],
    'File/Spec.pm'		    => [qw(
	File/Spec/Cygwin.pm
	File/Spec/Epoc.pm
	File/Spec/Functions.pm
	File/Spec/Mac.pm
	File/Spec/NW5.pm
	File/Spec/OS2.pm
	File/Spec/Unix.pm
	File/Spec/VMS.pm
	File/Spec/Win32.pm
    )],
    'IO/Socket.pm'		    => [qw( IO/Socket/UNIX.pm )],
    'Locale/Maketext/Lexicon.pm'    => [qw(
	Locale/Maketext/Lexicon/Auto.pm
	Locale/Maketext/Lexicon/Gettext.pm
	Locale/Maketext/Lexicon/Msgcat.pm
	Locale/Maketext/Lexicon/Tie.pm
    )],
    'LWP/UserAgent.pm'		    => [qw(
	URI/URL.pm
	URI/http.pm
	LWP/Protocol/http.pm
    )],
    'Net/FTP.pm'		    => [qw( Net/FTP/I.pm )],
    'Regexp/Common.pm'		    => [qw(
	Regexp/Common/URI.pm
	Regexp/Common/balanced.pm
	Regexp/Common/comment.pm
	Regexp/Common/delimited.pm
	Regexp/Common/list.pm
	Regexp/Common/net.pm
	Regexp/Common/number.pm
	Regexp/Common/profanity.pm
	Regexp/Common/whitespace.pm
    )],
    'Term/ReadLine.pm'		    => [qw(
	Term/ReadLine/readline.pm
	Term/ReadLine/Perl.pm
	Term/ReadLine/Gnu.pm
	Term/ReadLine/Gnu/XS.pm
	Term/ReadLine/Gnu/euc-jp.pm
    )],
    'Tk.pm'			    => [qw( Tk/FileSelect.pm )],
    'Tk/Balloon.pm'		    => [qw( Tk/balArrow.xbm )],
    'Tk/BrowseEntry.pm'		    => [qw( Tk/cbxarrow.xbm )],
    'Tk/ColorEditor.pm'		    => [qw( Tk/ColorEdit.xpm )],
    'Tk/FBox.pm'		    => [qw( Tk/folder.xpm Tk/file.xmp )],
    'Tk/Toplevel.pm'		    => [qw( Tk/Wm.pm )],
    'Win32/EventLog.pm'		    => [qw( Win32/IPC.pm )],
    'Win32/TieRegistry.pm'	    => [qw( Win32API/Registry.pm )],
);
# }}}

sub scan_deps {
    my %args = (
	(@_ and $_[0] =~ /^(?:files|keys|recurse|rv|skip)$/)
	    ? @_ : ( files => [ @_ ], recurse => 1 )
    );
    my ($files, $keys, $recurse, $rv, $skip) = @args{qw/files keys recurse rv skip/};

    $rv ||= {}; $skip ||= {};

    foreach my $file (@{$files}) {
	my $key = shift @{$keys};
	next if $skip->{$file}++;

	local *FH;
	open FH, $file or die "Cannot open $file: $!";

        # Line-by-line scanning {{{
	LINE: while (<FH>) {
	    chomp;
	    my $line = $_;
	    foreach ( scan_line($_) ) {
		last LINE if /^__END__$/;

		if (/^__POD__$/) {
		    while (<FH>) { last if (/^=cut/) }
		    next LINE;
		}

		next if /\.ph$/i;

		$_ = 'CGI/Apache.pm' if /^Apache(?:\.pm)$/;

		add_deps( used_by => $key, rv => $rv, modules => [ $_ ] );
		add_deps( used_by => $key, rv => $rv, modules => $Preload{$_} )
		    if exists $Preload{$_};
	    }
	}
	close FH;
        # }}}
    }

    # Top-level recursion handling {{{
    while ($recurse) {
	my $count = keys %$rv;
	my @files = sort grep -T $_->{file}, values %$rv;
	scan_deps(
	    files   => [ map $_->{file}, @files ],
	    keys    => [ map $_->{key},  @files ],
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

    $line =~ s/\s*#.*$//;
    $line =~ s/[\\\/]+/\//g;

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
	return $1 if /\b(?:use|no|require)\s+([\w:\.\-\\\/\"\']*)/;
	return $1 if /\b(?:use|no|require)\s+\(\s*([\w:\.\-\\\/\"\']*)\s*\)/;

	if (s/\beval\s+\"([^\"]+)\"/$1/ or s/\beval\s*\(\s*\"([^\"]+)\"\s*\)/$1/) {
	    return $1 if /\b(?:use|no|require)\s+([\w:\.\-\\\/\"\']*)/;
	}

	return "File::Glob" if /<[^>]*[^\$\w>][^>]*>/;
	return "DBD::$1" if /\bdbi:(\w+):/;
	return $1 if /\b(?:do|require)\s+[^"]*"(.*?)"/;
	return $1 if /\b(?:do|require)\s+[^']*'(.*?)'/;
	return $1 if /[^\$]\b([\w:]+)->\w/ and $1 ne 'Tk';
	return $1 if /([\w:]+)::\w/ and $1 ne 'Tk';
	return;
    };
    # }}}

    return unless defined($module) and $module =~ /^\w/;

    $module =~ s/\W+$//;
    $module =~ s/::/\//g;
    return if $module =~ /^(?:[\d\._]+|'.*[^']|".*[^"])$/;

    $module .= ".pm" unless $module =~ /\.pm/i;
    return $module;
}

sub _add_info {
    my ($rv, $module, $file, $used_by, $type) = @_;
    return unless defined($module) and defined($file);

    $rv->{$module} ||= {
	file	=> $file,
	key	=> $module,
	type	=> $type,
    };

    push @{$rv->{$module}{used_by}}, $used_by
	if defined($used_by) and $used_by ne $module
	   and !grep { $_ eq $used_by } @{$rv->{$module}{used_by}};
}

sub add_deps {
    my %args = (
	(@_ and $_[0] =~ /^(?:modules|rv|used_by)$/)
	    ? @_ : ( rv => ( ref($_[0]) ? shift(@_) : undef ), modules => [ @_ ] )
    );

    my $rv = $args{rv} || {};
    my $used_by = $args{used_by};

    foreach my $module (@{$args{modules}}) {
	next if exists $rv->{$module};

	my $file = _find_in_inc($module) or next;
	my $type = 'module';
	$type = 'data' unless $file =~ /\.pm$/i;
	_add_info($rv, $module, $file, $used_by, $type);

	if ($module =~ /(.*?([^\/]*))\.pm$/i) {
	    my ($path, $basename) = ($1, $2);

            # Shared objects {{{
	    if (defined $basename) {
		my $dl_name = "auto/$path/$basename" . dl_ext();
		my $dl_file = _find_in_inc($dl_name) ||
			      _find_in_inc($basename . dl_ext());
		_add_info($rv, $dl_name, $dl_file, $module, 'shared');
	    }
            # }}}
            # Autosplit files {{{
	    my $autosplit_dir = _find_in_inc("auto/$path/autosplit.ix") or next;
	    $autosplit_dir =~ s/\/autosplit\.ix$//;

	    local *DIR;
	    opendir(DIR, $autosplit_dir) or next;
	    _add_info(
		$rv, "auto/$path/$_", "$autosplit_dir/$_", $module, 'autoload'
	    ) foreach grep /\.(?:ix|al)$/i, readdir(DIR);
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

# App::Packer compatibility mode

sub new {
    my ($class, $self) = @_;
    return bless($self ||= {}, $class);
}

sub set_file {
    my $self = shift;
    foreach my $script ( @_ ) {
	my $basename = $script;
	$basename =~ s/.*\///;
	$self->{main} = {
	    key	    => $basename,
	    file    => $script,
	};
    }
}

sub set_options {
    my $self = shift;
    my %args = @_;
    foreach my $module (@{$args{add_modules}}) {
	$module =~ s/::/\//g;
	$module .= '.pm' unless $module =~ /\.pm$/i;
	my $file = _find_in_inc($module) or next;
	$self->{files}{$module} = $file;
    }
}

sub calculate_info {
    my $self = shift;
    my $rv = scan_deps(
	keys	=> [
	    $self->{main}{key},
	    sort keys %{$self->{files}},
	],
	files	=> [
	    $self->{main}{file},
	    map { $self->{files}{$_} } sort keys %{$self->{files}},
	],
	recurse	=> 1,
    );

    my $info = {
	main => {
	    file	=> $self->{main}{file},
	    store_as	=> $self->{main}{key},
	},
    };

    my %cache = ( $self->{main}{key} => $info->{main} );
    foreach my $key (keys %{$self->{files}}) {
	my $file = $self->{files}{$key};

	$cache{$key} = $info->{modules}{$key} = {
	    file	=> $file,
	    store_as    => $key,
	    used_by	=> [ $self->{main}{key} ],
	}
    }

    foreach my $key (keys %{$rv}) {
	my $val = $rv->{$key};
	if ($cache{$val->{key}}) {
	    push @{$info->{$val->{type}}->{$val->{key}}->{used_by}}, @{$val->{used_by}};
	}
	else {
	    $cache{$val->{key}} = $info->{$val->{type}}->{$val->{key}} = {
		file	    => $val->{file},
		store_as    => $val->{key},
		used_by	    => $val->{used_by},
	    };
	}
    }

    foreach my $type (keys %{$info}) {
	next if $type eq 'main';
	my @val;
	foreach my $val ( values %{$info->{$type}} ) {
	    @{$val->{used_by}} = map $cache{$_} || "!!$_!!", @{$val->{used_by}};
	    push @val, $val;
	}
	delete $info->{$type};
	$type = 'modules' if $type eq 'module';
	$info->{$type} = \@val;
    }

    $self->{info} = $info;
}

sub get_files {
    my $self = shift;
    return $self->{info};
}

1;

__END__

=head1 SEE ALSO

An application of B<Module::ScanDeps> is to generate executables from
scripts that contains necessary modules; this module supports two such
projects, L<PAR> and L<App::Packer>.  Please see their respective
documentations on CPAN for further information.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Part of heuristics are taken from B<Perl2Exe>
by IndigoStar, Inc L<http://www.indigostar.com/>

Part of heuristics are deduced from B<PerlApp>
by ActiveState Tools Corp L<http://www.activestate.com/>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
