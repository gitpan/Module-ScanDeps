# $File: //member/autrijus/Module-ScanDeps/ScanDeps.pm $ $Author: autrijus $
# $Revision: #43 $ $Change: 7559 $ $DateTime: 2003/08/16 04:37:06 $

package Module::ScanDeps;
use vars qw/$VERSION @EXPORT @EXPORT_OK/;

$VERSION    = '0.27';
@EXPORT	    = qw(scan_deps);
@EXPORT_OK  = qw(scan_line scan_chunk add_deps);

use strict;
use Exporter;
use base 'Exporter';
use Config;
use constant dl_ext => ".$Config{dlext}";
use constant lib_ext => $Config{lib_ext};

=head1 NAME

Module::ScanDeps - Recursively scan Perl code for dependencies

=head1 VERSION

This document describes version 0.27 of Module::ScanDeps, released
August 16, 2003.

=head1 SYNOPSIS

Via the command-line program L<scandeps.pl>:

    % scandeps.pl *.pm		# Print PREREQ_PM section for *.pm
    % scandeps.pl -e "use utf8"	# Read script from command line
    % scandeps.pl -B *.pm	# Include core modules
    % scandeps.pl -V *.pm	# Show autoload/shared/data files

Used in a program;

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
    @modules = scan_chunk($chunk);

Apply various heuristics to C<$chunk> to find and return the module
name(s) it contains.  In scalar context, returns only the first module
or C<undef>.

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

Finally, since no source code are actually compiled by this module,
so the heuristic is not likely to be 100% accurate.  Patches welcome!

=cut

my $SeenTk;

# Pre-loaded module dependencies {{{
my %Preload = (
    'AnyDBM_File.pm'		    => [qw( SDBM_File.pm )],
    'Authen/SASL.pm'		    => 'sub',
    'Crypt/Random.pm'		    => sub {
	_glob_in_inc('Crypt/Random/Provider', 1);
    },
    'Crypt/Random/Generator.pm'	    => sub {
	_glob_in_inc('Crypt/Random/Provider', 1);
    },
    'DBI.pm'			    => sub {
	grep !/\bProxy\b/, _glob_in_inc('DBD', 1);
    },
    'Device/SerialPort.pm'	    => [qw(
	termios.ph asm/termios.ph sys/termiox.ph sys/termios.ph sys/ttycom.ph
    )],
    'ExtUtils/MakeMaker.pm'	    => sub {
	grep /\bMM_/, _glob_in_inc('ExtUtils', 1);
    },
    'File/Basename.pm'		    => [qw( re.pm )],
    'File/Spec.pm'		    => sub {
	require File::Spec;
	map { my $name = $_; $name =~ s!::!/!g; "$name.pm" } @File::Spec::ISA;
    },
    'HTTP/Message.pm'		    => [qw(
	URI/URL.pm	    URI.pm
    )],
    'IO.pm'			    => [qw(
	IO/Handle.pm	    IO/Seekable.pm	IO/File.pm
	IO/Pipe.pm	    IO/Socket.pm	IO/Dir.pm
    )],
    'IO/Socket.pm'		    => [qw( IO/Socket/UNIX.pm )],
    'LWP/UserAgent.pm'		    => [qw(
	URI/URL.pm	    URI/http.pm		LWP/Protocol/http.pm
    )],
    'Locale/Maketext/Lexicon.pm'    => 'sub',
    'Math/BigInt.pm'		    => [qw( Math::BigInt::Calc )],
    'Module/Build.pm'		    => 'sub',
    'MIME/Decoder.pm'		    => 'sub',
    'Net/DNS/RR.pm'		    => 'sub',
    'Net/FTP.pm'		    => 'sub',
    'Net/SSH/Perl'		    => 'sub',
    'Regexp/Common.pm'		    => 'sub',
    'SOAP/Lite.pm'		    => sub {(
	($] >= 5.008 ? ('utf8.pm') : ()),
	_glob_in_inc('SOAP/Transport', 1),
    )},
    'SQL/Parser.pm'		    => sub {
	_glob_in_inc('SQL/Dialects', 1);
    },
    'SerialJunk.pm'		    => [qw(
	termios.ph asm/termios.ph sys/termiox.ph sys/termios.ph sys/ttycom.ph
    )],
    'Template.pm'		    => 'sub',
    'Term/ReadLine.pm'		    => 'sub',
    'Tk.pm'			    => sub {
	$SeenTk = 1;
	'Tk/FileSelect.pm';
    },
    'Tk/Balloon.pm'		    => [qw( Tk/balArrow.xbm )],
    'Tk/BrowseEntry.pm'		    => [qw( Tk/cbxarrow.xbm )],
    'Tk/ColorEditor.pm'		    => [qw( Tk/ColorEdit.xpm )],
    'Tk/FBox.pm'		    => [qw( Tk/folder.xpm Tk/file.xpm )],
    'Tk/Toplevel.pm'		    => [qw( Tk/Wm.pm )],
    'URI.pm'			    => sub {
	grep !/.\b[_A-Z]/, _glob_in_inc('URI', 1);
    },
    'Win32/EventLog.pm'		    => [qw( Win32/IPC.pm )],
    'Win32/TieRegistry.pm'	    => [qw( Win32API/Registry.pm )],
    'Win32/SystemInfo.pm'	    => [qw( Win32/cpuspd.dll )],
    'XML/Parser/Expat.pm'	    => sub {
	($] >= 5.008) ? ('utf8.pm') : ();
    },
    'XMLRPC/Lite.pm'		    => sub {
	_glob_in_inc('XMLRPC/Transport', 1),
    },
    'diagnostics.pm'		    => sub {
	_find_in_inc('Pod/perldiag.pod') ? 'Pod/perldiag.pl' : 'pod/perldiag.pod'
    },
    'utf8.pm'			    => [
	'utf8_heavy.pl', do {
	    my @files;
	    if (@files = map "unicore/lib/$_->{name}", _glob_in_inc('unicore/lib')) {
		push @files, map "unicore/$_.pl", qw(Exact Canonical);
	    }
	    elsif (@files = map "unicode/Is/$_->{name}", _glob_in_inc('unicode/Is')) {
		push @files, map "unicode/In/$_->{name}", _glob_in_inc('unicode/In');
		push @files, map "unicode/To/$_->{name}", _glob_in_inc('unicode/To');
	    }
	    @files;
	}
    ],
    'charnames.pm'		    => [
	_find_in_inc('unicore/Name.pl') ? 'unicore/Name.pl' : 'unicode/Name.pl'
    ],
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

	$SeenTk = 0;
        # Line-by-line scanning {{{
	LINE: while (<FH>) {
	    chomp;
	    my $line = $_;
	    foreach my $pm ( scan_line($_) ) {
		last LINE if $pm eq '__END__';

		if ($pm eq '__POD__') {
		    while (<FH>) { last if (/^=cut/) }
		    next LINE;
		}

		$pm = 'CGI/Apache.pm' if /^Apache(?:\.pm)$/;

		add_deps( used_by => $key, rv => $rv, modules => [ $pm ], skip => $skip );
		my $preload = $Preload{$pm} or next;
		if ($preload eq 'sub') {
		    $pm =~ s/\.pm$//i;
		    $preload = [_glob_in_inc($pm, 1)];
		}
		elsif (UNIVERSAL::isa($preload, 'CODE')) {
		    $preload = [ $preload->($pm) ];
		}
		add_deps( used_by => $key, rv => $rv, modules => $preload, skip => $skip );
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

	if (my($libs) = /\b(?:use\s+lib\s+|(?:unshift|push)\W+\@INC\W+)(.+)/) {
	    my $archname = defined($Config{archname}) ? $Config{archname} : '';
	    my $ver = defined($Config{version}) ? $Config{version} : '';
	    foreach (grep(/\w/, split(/["';() ]/, $libs))) {
		unshift(@INC, "$_/$ver")		if -d "$_/$ver";
		unshift(@INC, "$_/$archname")		if -d "$_/$archname";
		unshift(@INC, "$_/$ver/$archname")	if -d "$_/$ver/$archname";
	    }
	    next;
	}

	$found{$_}++ for scan_chunk($_);
    }

    return sort keys %found;
}

sub scan_chunk {
    my $chunk = shift;

    # Module name extraction heuristics {{{
    my $module = eval {
	$_ = $chunk;

	return [ 'base.pm', grep { !/^q[qw]?$/ } split(/[^\w:]+/, $1) ]
	    if /^\s* use \s+ base \s+ (.*)/x;
	return $1 if /(?:^|\s)(?:use|no|require)\s+([\w:\.\-\\\/\"\']+)/;
	return $1 if /(?:^|\s)(?:use|no|require)\s+\(\s*([\w:\.\-\\\/\"\']+)\s*\)/;

	if (s/(?:^|\s)eval\s+\"([^\"]+)\"/$1/ or s/(?:^|\s)eval\s*\(\s*\"([^\"]+)\"\s*\)/$1/) {
	    return $1 if /(?:^|\s)(?:use|no|require)\s+([\w:\.\-\\\/\"\']*)/;
	}

	return "File/Glob.pm" if /<[^>]*[^\$\w>][^>]*>/;
	return "DBD/$1.pm" if /\b[Dd][Bb][Ii]:(\w+):/;
	return $1 if /(?:^|\s)(?:do|require)\s+[^"]*"(.*?)"/;
	return $1 if /(?:^|\s)(?:do|require)\s+[^']*'(.*?)'/;
	return $1 if /[^\$]\b([\w:]+)->\w/ and $1 ne 'Tk';
	return $1 if /([\w:]+)::\w/ and $1 ne 'Tk' and $1 ne 'PAR';

	if ($SeenTk) {
	    my @modules;
	    while (/->\s*([A-Z]\w+)/g) {
		push @modules, "Tk/$1.pm";
	    }
	    while (/->\s*Scrolled\W+([A-Z]\w+)/g) {
		push @modules, "Tk/$1.pm";
		push @modules, "Tk/Scrollbar.pm";
	    }
	    return \@modules;
	}
	return;
    };
    # }}}

    return unless defined($module);
    return wantarray ? @$module : $module->[0] if ref($module);

    $module =~ s/^['"]//;
    return unless $module =~ /^\w/;

    $module =~ s/\W+$//;
    $module =~ s/::/\//g;
    return if $module =~ /^(?:[\d\._]+|'.*[^']|".*[^"])$/;

    $module .= ".pm" unless $module =~ /\./;
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
    my $skip = $args{skip} || {};
    my $used_by = $args{used_by};

    foreach my $module (@{$args{modules}}) {
	next if exists $rv->{$module};

	my $file = _find_in_inc($module) or next;
	next if $skip->{$file};
	my $type = 'module';
	$type = 'data' unless $file =~ /\.p[mh]$/i;
	_add_info($rv, $module, $file, $used_by, $type);

	if ($module =~ /(.*?([^\/]*))\.p[mh]$/i) {
	    my ($path, $basename) = ($1, $2);

	    foreach (_glob_in_inc("auto/$path")) {
		next if $_->{file} =~ m{\bauto/$path/.*/}; # weed out subdirs
		next if $_->{name} =~ m/(?:^|\/)\.(?:exists|packlist)$/;
		my $ext = lc($1) if $_->{name} =~ /(\.[^.]+)$/;
		next if $ext eq lc(lib_ext());
		my $type = 'shared' if $ext eq lc(dl_ext());
		$type = 'autoload'  if $ext eq '.ix' or $ext eq '.al';
		$type ||= 'data';

		_add_info($rv, "auto/$path/$_->{name}", $_->{file}, $module, $type);
	    }
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

sub _glob_in_inc {
    my $subdir = shift;
    my $pm_only = shift;
    my @files;

    require File::Find;

    foreach my $dir (map "$_/$subdir", grep !/\bBSDPAN\b/, @INC) {
	next unless -d $dir;
	File::Find::find(sub {
	    my $name = $File::Find::name;
	    $name =~ s!^\Q$dir\E/!!;
	    next if $pm_only and lc($name) !~ /\.pm$/;
	    push @files, $pm_only ? "$subdir/$name" : {
		file => $File::Find::name,
		name => $name,
	    } if -f;
	}, $dir);
    }

    return @files;
}

# App::Packer compatibility functions

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
	$module .= '.pm' unless $module =~ /\.p[mh]$/i;
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

    $self->{info} = { main => $info->{main} };

    foreach my $type (keys %{$info}) {
	next if $type eq 'main';

	my @val;
	if (UNIVERSAL::isa($info->{$type}, 'HASH')) {
	    foreach my $val ( values %{$info->{$type}} ) {
		@{$val->{used_by}} = map $cache{$_} || "!!$_!!", @{$val->{used_by}};
		push @val, $val;
	    }
	}

	$type = 'modules' if $type eq 'module';
	$self->{info}{$type} = \@val;
    }
}

sub get_files {
    my $self = shift;
    return $self->{info};
}

1;

__END__

=head1 SEE ALSO

L<scandeps.pl> is a bundled utility that writes C<PREREQ_PM> section
for a number of files.

An application of B<Module::ScanDeps> is to generate executables from
scripts that contains necessary modules; this module supports two such
projects, L<PAR> and L<App::Packer>.  Please see their respective
documentations on CPAN for further information.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Part of heuristics were deduced from:

=over 4

=item *

B<PerlApp> by ActiveState Tools Corp L<http://www.activestate.com/>

=item *

B<Perl2Exe> by IndigoStar, Inc L<http://www.indigostar.com/>

=back

L<http://par.perl.org/> is the official website for this module.  You
can write to the mailing list at E<lt>par@perl.orgE<gt>, or send an empty
mail to E<lt>par-subscribe@perl.orgE<gt> to participate in the discussion.

Please submit bug reports to E<lt>bug-Module-ScanDeps@rt.cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2002, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
