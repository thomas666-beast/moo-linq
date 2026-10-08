use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- Where ---
my @evens = Moo::LINQ->Range(1, 10)
    ->Where(sub { $_ % 2 == 0 })
    ->ToArray();
is_deeply \@evens, [2, 4, 6, 8, 10], 'Where filters evens';

# --- WhereNot ---
my @odds = Moo::LINQ->Range(1, 10)
    ->WhereNot(sub { $_ % 2 == 0 })
    ->ToArray();
is_deeply \@odds, [1, 3, 5, 7, 9], 'WhereNot keeps odds';

# --- Chained Where ---
my @r = Moo::LINQ->Range(1, 100)
    ->Where(sub { $_ % 2 == 0 })
    ->Where(sub { $_ % 3 == 0 })
    ->ToArray();
is_deeply \@r, [6, 12, 18, 24, 30, 36, 42, 48, 54, 60,
                66, 72, 78, 84, 90, 96], 'Chained Where intersects';

# --- Take ---
@r = Moo::LINQ->Range(1, 100)->Take(3)->ToArray();
is_deeply \@r, [1, 2, 3], 'Take limits lazily';

# --- Skip ---
@r = Moo::LINQ->Range(1, 5)->Skip(2)->ToArray();
is_deeply \@r, [3, 4, 5], 'Skip drops first N';

# --- Take then Skip ---
@r = Moo::LINQ->Range(1, 100)->Skip(10)->Take(3)->ToArray();
is_deeply \@r, [11, 12, 13], 'Skip+Take window';

# --- TakeWhile ---
@r = Moo::LINQ->Range(1, 100)->TakeWhile(sub { $_ < 5 })->ToArray();
is_deeply \@r, [1, 2, 3, 4], 'TakeWhile stops at first failure';

# --- SkipWhile ---
@r = Moo::LINQ->Range(1, 10)->SkipWhile(sub { $_ < 5 })->ToArray();
is_deeply \@r, [5, 6, 7, 8, 9, 10], 'SkipWhile starts after condition';

# --- Distinct ---
@r = Moo::LINQ->From([1, 2, 2, 3, 3, 3, 4])->Distinct()->ToArray();
is_deeply \@r, [1, 2, 3, 4], 'Distinct removes duplicates';

# --- First ---
my $first = Moo::LINQ->Range(5, 100)->First();
is $first, 5, 'First returns first item';

$first = Moo::LINQ->Range(1, 10)->First(sub { $_ > 5 });
is $first, 6, 'First with predicate';

# --- FirstOrDefault ---
my $val = Moo::LINQ->Empty()->FirstOrDefault('none');
is $val, 'none', 'FirstOrDefault returns default on empty';

$val = Moo::LINQ->Range(1, 3)->FirstOrDefault('none', sub { $_ > 10 });
is $val, 'none', 'FirstOrDefault with unmatched predicate';

# --- Any ---
ok( Moo::LINQ->Range(1, 5)->Any(sub { $_ == 3 }), 'Any true when match' );
ok( !Moo::LINQ->Range(1, 5)->Any(sub { $_ == 10 }), 'Any false when no match' );

# --- All ---
ok( Moo::LINQ->Range(2, 10, 2)->All(sub { $_ % 2 == 0 }), 'All true for evens' );
ok( !Moo::LINQ->Range(1, 5)->All(sub { $_ % 2 == 0 }), 'All false when odd present' );

done_testing;
