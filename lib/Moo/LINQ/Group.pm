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
