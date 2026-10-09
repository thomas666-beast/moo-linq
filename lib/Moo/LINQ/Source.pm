package Moo::LINQ::Source;

# ABSTRACT: File-based data sources for Moo::LINQ

use Moo::Role;
use strict;
use warnings;

use Moo::LINQ::Source::Lines;
use Moo::LINQ::Source::CSV;
use Moo::LINQ::Source::TSV;
use Moo::LINQ::Source::LTSV;
use Moo::LINQ::Source::JSON;
use Moo::LINQ::Source::SQLite;

sub FromLines {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::Lines->new(path => $path, %opts);
    return $class->new(_iterator => $src->iterator);
}

sub FromCSV {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::CSV->new(path => $path, %opts);
    return $class->new(_iterator => $src->iterator);
}

sub FromTSV {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::TSV->new(path => $path, %opts);
    return $class->new(_iterator => $src->iterator);
}

sub FromLTSV {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::LTSV->new(path => $path, %opts);
    return $class->new(_iterator => $src->iterator);
}

sub FromJSON {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::JSON->new(path => $path, %opts);
    return $class->new(_iterator => $src->iterator);
}

sub FromSQLite {
    my ($class, $path, $query, $params) = @_;
    my $src = Moo::LINQ::Source::SQLite->new(
        path   => $path,
        query  => $query,
        params => $params || [],
    );
    return $class->new(_iterator => $src->iterator);
}

1;

__END__

=head1 NAME

Moo::LINQ::Source - File-based data sources for Moo::LINQ

=head1 SYNOPSIS

    use Moo::LINQ;

    my @lines  = Moo::LINQ->FromLines('notes.txt')->ToArray();
    my @rows   = Moo::LINQ->FromCSV('data.csv')->ToArray();
    my @tabbed = Moo::LINQ->FromTSV('data.tsv')->ToArray();
    my @ltsv   = Moo::LINQ->FromLTSV('access.log.ltsv')->ToArray();
    my @json   = Moo::LINQ->FromJSON('users.json')->ToArray();

=head1 DESCRIPTION

Adds file-reading constructors to L<Moo::LINQ>:

=over 4

=item * C<FromLines> -- line-by-line text (streaming)

=item * C<FromCSV> -- CSV with optional header (streaming)

=item * C<FromTSV> -- tab-separated (streaming)

=item * C<FromLTSV> -- labeled TSV as hashrefs (streaming)

=item * C<FromJSON> -- top-level JSON array (buffered)

=back

All sources except C<FromJSON> stream one record at a time; the entire
file is never loaded into memory. C<FromJSON> must buffer because the
JSON format itself is not streamable without a special parser.

=head1 OPTIONS

B<FromLines>: C<chomp> (default 1), C<skip_blank> (default 1).

B<FromCSV>: C<delimiter> (default C<,>), C<header> (default 1).

B<FromTSV>: same options as C<FromCSV>, with C<delimiter> defaulted to tab.

B<FromLTSV>: C<chomp> (default 1).

B<FromJSON>: no options.

=head1 SEE ALSO

L<Moo::LINQ>

=cut
