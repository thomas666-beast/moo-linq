package Moo::LINQ::Source::LTSV;

# ABSTRACT: LTSV file source for Moo::LINQ

use Moo;
use strict;
use warnings;

has path    => (is => 'ro', required => 1);
has chomp   => (is => 'ro', default  => sub { 1 });
has fh      => (is => 'ro', lazy => 1, builder => '_build_fh');

sub _build_fh {
    my $self = shift;
    open my $fh, '<', $self->path
        or die "Cannot open '$self->{path}': $!";
    return $fh;
}

sub _parse_line {
    my ($self, $line) = @_;
    my %out;
    for my $pair (split /\t/, $line, -1) {
        next if $pair eq '';
        my ($k, $v) = split /:/, $pair, 2;
        next unless defined $k && defined $v;
        $out{$k} = $v;
    }
    return \%out;
}

sub iterator {
    my $self  = shift;
    my $fh    = $self->fh;
    my $chomp = $self->chomp;

    return sub {
        while (defined(my $line = <$fh>)) {
            chomp $line if $chomp;
            next if $line eq '';
            return $self->_parse_line($line);
        }
        return undef;
    };
}

1;

__END__

=head1 NAME

Moo::LINQ::Source::LTSV - LTSV file source for Moo::LINQ

=head1 SYNOPSIS

    my @rows = Moo::LINQ->FromLTSV('access.log.ltsv')
        ->Where(sub { $_->{status} eq '200' })
        ->ToArray();

=head1 DESCRIPTION

Streams an LTSV (Labeled Tab-Separated Values) file one record at a time,
yielding a hashref per line. Missing values are returned as empty strings.

See L<http://ltsv.org/> for the format specification.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>

=cut
