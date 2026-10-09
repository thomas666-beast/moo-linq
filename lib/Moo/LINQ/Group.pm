package Moo::LINQ::Group;

use Moo;

our $VERSION = '0.02';

has key   => (is => 'ro');
has items => (is => 'ro', default => sub { [] });

sub Count   { return scalar @{ $_[0]->items } }
sub ToArray { return @{ $_[0]->items } }
sub ToList  { return $_[0]->items }
sub AsQuery {
    require Moo::LINQ;
    return Moo::LINQ->From($_[0]->items);
}

1;

__END__

=head1 NAME

Moo::LINQ::Group - Group result object for Moo::LINQ::GroupBy

=head1 DESCRIPTION

Represents one group produced by C<GroupBy>. Provides C<key>, C<items>,
C<Count>, C<ToArray>, C<ToList>, and C<AsQuery>.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Grouping>

=cut
