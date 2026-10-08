use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- Concat ---
my @r = Moo::LINQ->From([1, 2, 3])
    ->Concat([4, 5])
    ->ToArray();
is_deeply \@r, [1, 2, 3, 4, 5], 'Concat';

# --- Union ---
@r = Moo::LINQ->From([1, 2, 3, 4])
    ->Union([3, 4, 5, 6])
    ->ToArray();
is_deeply \@r, [1, 2, 3, 4, 5, 6], 'Union deduplicates';

# --- Intersect ---
@r = Moo::LINQ->From([1, 2, 3, 4])
    ->Intersect([3, 4, 5, 6])
    ->ToArray();
is_deeply \@r, [3, 4], 'Intersect';

# --- Except ---
@r = Moo::LINQ->From([1, 2, 3, 4])
    ->Except([3, 4, 5, 6])
    ->ToArray();
is_deeply \@r, [1, 2], 'Except';

# --- Concat lazy ---
my @trace;
my $lazy = sub { push @trace, "yield $_[0]"; return $_[0] };
@r = Moo::LINQ->From([1, 2])
    ->Select($lazy)
    ->Concat([3, 4])
    ->Take(3)
    ->ToArray();
is_deeply \@r, [1, 2, 3], 'Concat then Take';
is scalar @trace, 2, 'Concat is lazy (only pulled 2 from first seq)';

done_testing;
