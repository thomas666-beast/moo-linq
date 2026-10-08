use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- Contains ---
ok(  Moo::LINQ->Range(1, 5)->Contains(3), 'Contains true');
ok( !Moo::LINQ->Range(1, 5)->Contains(10), 'Contains false');

# --- SequenceEqual ---
ok( Moo::LINQ->From([1,2,3])->SequenceEqual([1,2,3]), 'SequenceEqual true');
ok(!Moo::LINQ->From([1,2,3])->SequenceEqual([1,2,4]), 'SequenceEqual false value');
ok(!Moo::LINQ->From([1,2,3])->SequenceEqual([1,2]),   'SequenceEqual false length');
ok( Moo::LINQ->Empty()->SequenceEqual([]), 'SequenceEqual empty vs empty');

# --- ElementAt ---
is( Moo::LINQ->Range(10, 20)->ElementAt(0), 10, 'ElementAt 0');
is( Moo::LINQ->Range(10, 20)->ElementAt(5), 15, 'ElementAt 5');

my $ok = eval { Moo::LINQ->Range(1, 3)->ElementAt(99); 1 };
ok( !$ok, 'ElementAt out of range dies' );

is( Moo::LINQ->Range(1, 3)->ElementAtOrDefault(99, 'X'), 'X', 'ElementAtOrDefault');

# --- Single ---
is( Moo::LINQ->From([42])->Single(), 42, 'Single unique' );
$ok = eval { Moo::LINQ->Empty()->Single(); 1 };
ok( !$ok, 'Single on empty dies' );
$ok = eval { Moo::LINQ->From([1,2])->Single(); 1 };
ok( !$ok, 'Single on multiple dies' );

is( Moo::LINQ->Range(1, 10)->Single(sub { $_ == 7 }), 7, 'Single with predicate' );

# --- SingleOrDefault ---
is( Moo::LINQ->Empty()->SingleOrDefault('X'), 'X', 'SingleOrDefault empty' );
is( Moo::LINQ->From([42])->SingleOrDefault('X'), 42, 'SingleOrDefault present' );

# --- Last ---
is( Moo::LINQ->Range(1, 10)->Last(), 10, 'Last' );
is( Moo::LINQ->Range(1, 10)->Last(sub { $_ % 2 == 0 }), 10, 'Last even' );
$ok = eval { Moo::LINQ->Empty()->Last(); 1 };
ok( !$ok, 'Last on empty dies' );

# --- LastOrDefault ---
is( Moo::LINQ->Empty()->LastOrDefault('X'), 'X', 'LastOrDefault empty' );
is( Moo::LINQ->Range(1, 5)->LastOrDefault('X'), 5, 'LastOrDefault present' );

# --- DefaultIfEmpty ---
my @r = Moo::LINQ->Empty()->DefaultIfEmpty('X')->ToArray();
is_deeply \@r, ['X'], 'DefaultIfEmpty on empty yields default';

@r = Moo::LINQ->Range(1, 3)->DefaultIfEmpty('X')->ToArray();
is_deeply \@r, [1, 2, 3], 'DefaultIfEmpty on non-empty passes through';

done_testing;
