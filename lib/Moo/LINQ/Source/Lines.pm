package Moo::LINQ::Source::Lines;

# ABSTRACT: Line-by-line file source for Moo::LINQ

use Moo;
use strict;
use warnings;

has path       => (is => 'ro', required => 1);
has chomp      => (is => 'ro', default  => sub { 1 });
has skip_blank => (is => 'ro', default  => sub { 1 });
has fh         => (is => 'ro', lazy => 1, builder => '_build_fh');

sub _build_fh {
    my $self = shift;
    open my $fh, '<', $self->path
        or die "Cannot open '$self->{path}': $!";
    return $fh;
}

sub iterator {
    my $self  = shift;
    my $fh    = $self->fh;
    my $chomp = $self->chomp;
    my $skip  = $self->skip_blank;

    return sub {
        while (defined(my $line = <$fh>)) {
            chomp $line if $chomp;
            next if $skip && $line eq '';
            return $line;
        }
        return undef;
    };
}

1;

__END__

=head1 NAME

Moo::LINQ::Source::Lines - Line-by-line file source for Moo::LINQ

=head1 DESCRIPTION

Streams a text file one line at a time. Used indirectly through
C<Moo::LINQ->FromLines>. Options: C<chomp> (default 1),
C<skip_blank> (default 1).

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>

=cut
