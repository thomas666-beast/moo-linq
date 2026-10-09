package Moo::LINQ::Source::CSV;

# ABSTRACT: CSV file source for Moo::LINQ

use Moo;
use strict;
use warnings;

has path      => (is => 'ro', required => 1);
has delimiter => (is => 'ro', default  => sub { ',' });
has header    => (is => 'ro', default  => sub { 1 });
has fh        => (is => 'ro', lazy => 1, builder => '_build_fh');
has columns   => (is => 'ro', lazy => 1, builder => '_build_columns');

sub _build_fh {
    my $self = shift;
    open my $fh, '<', $self->path
        or die "Cannot open '$self->{path}': $!";
    return $fh;
}

sub _build_columns {
    my $self = shift;
    return undef unless $self->header;

    my $line = $self->_read_row;
    return undef unless defined $line;
    return $line;
}

sub _read_row {
    my $self = shift;
    my $fh   = $self->fh;
    my $delim = $self->delimiter;

    my $line = <$fh>;
    return undef unless defined $line;

    chomp $line;
    return $self->_parse_line($line);
}

sub _parse_line {
    my ($self, $line) = @_;
    my $delim = $self->delimiter;

    my @fields;
    my $field = '';
    my $in_quotes = 0;
    my $i = 0;
    my $len = length $line;

    while ($i < $len) {
        my $c = substr($line, $i, 1);

        if ($in_quotes) {
            if ($c eq '"') {
                if ($i + 1 < $len && substr($line, $i + 1, 1) eq '"') {
                    $field .= '"';
                    $i += 2;
                    next;
                }
                $in_quotes = 0;
                $i++;
                next;
            }
            $field .= $c;
            $i++;
            next;
        }

        if ($c eq '"' && $field eq '') {
            $in_quotes = 1;
            $i++;
            next;
        }

        if ($c eq $delim) {
            push @fields, $field;
            $field = '';
            $i++;
            next;
        }

        $field .= $c;
        $i++;
    }

    push @fields, $field;
    return \@fields;
}

sub iterator {
    my $self    = shift;
    my $columns = $self->columns;

    return sub {
        my $row = $self->_read_row;
        return undef unless defined $row;

        if ($columns) {
            my %hash;
            for my $i (0 .. $#$columns) {
                $hash{ $columns->[$i] } = $row->[$i];
            }
            return \%hash;
        }

        # No header: return arrayref
        return $row;
    };
}

1;

__END__

=head1 NAME

Moo::LINQ::Source::CSV - CSV file source for Moo::LINQ

=head1 DESCRIPTION

Streaming CSV reader. Used indirectly through C<Moo::LINQ->FromCSV>.
Supports custom delimiters, optional header row, and RFC-4180-style
quoted fields.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>

=cut
