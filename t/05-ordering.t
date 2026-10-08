use strict;
use warnings;
use Test::More;
use Moo::LINQ;

my @r = Moo::LINQ->From([3, 1, 4, 1, 5, 9, 2, 6])
    ->OrderBy(sub { $_ })
    ->ToArray();
is_deeply \@r, [1, 1, 2, 3, 4, 5, 6, 9], 'OrderBy ascending';

@r = Moo::LINQ->From([3, 1, 4, 1, 5, 9, 2, 6])
    ->OrderByDescending(sub { $_ })
    ->ToArray();
is_deeply \@r, [9, 6, 5, 4, 3, 2, 1, 1], 'OrderByDescending';

my @people = (
    { name => 'Carol', age => 35 },
    { name => 'Alice', age => 30 },
    { name => 'Bob',   age => 25 },
);
@r = Moo::LINQ->From(\@people)
    ->OrderBy(sub { $_->{age} })
    ->Select(sub { $_->{name} })
    ->ToArray();
is_deeply \@r, [qw(Bob Alice Carol)], 'OrderBy age then select name';

my @words = qw(banana apple cherry fig date elderberry);
@r = Moo::LINQ->From(\@words)
    ->OrderBy(sub { length $_ })
    ->ThenBy(sub { $_ })
    ->ToArray();
is_deeply \@r, [qw(fig date apple banana cherry elderberry)],
    'OrderBy length then alphabetical';

@r = Moo::LINQ->From(\@words)
    ->OrderBy(sub { length $_ })
    ->ThenByDescending(sub { $_ })
    ->ToArray();
is_deeply \@r, [qw(fig date apple cherry banana elderberry)],
    'OrderBy length then reverse alphabetical';

my @records = (
    { dept => 'B', name => 'Bob',   age => 30 },
    { dept => 'A', name => 'Alice', age => 25 },
    { dept => 'A', name => 'Aaron', age => 40 },
    { dept => 'B', name => 'Bill',  age => 20 },
    { dept => 'A', name => 'Alice', age => 30 },
);
@r = Moo::LINQ->From(\@records)
    ->OrderBy(sub { $_->{dept} })
    ->ThenBy(sub { $_->{name} })
    ->ThenByDescending(sub { $_->{age} })
    ->Select(sub { "$_->{dept}:$_->{name}:$_->{age}" })
    ->ToArray();
is_deeply \@r, [
    'A:Aaron:40',
    'A:Alice:30',
    'A:Alice:25',
    'B:Bill:20',
    'B:Bob:30',
], 'Three-level sort';

@r = Moo::LINQ->Range(1, 5)->Reverse()->ToArray();
is_deeply \@r, [5, 4, 3, 2, 1], 'Reverse';

@r = Moo::LINQ->From([5, 2, 8, 1, 9, 3])
    ->OrderBy(sub { $_ })
    ->Take(3)
    ->ToArray();
is_deeply \@r, [1, 2, 3], 'OrderBy then Take (top 3)';

eval { Moo::LINQ->Range(1, 5)->ThenBy(sub { $_ }) };
like $@, qr/must follow/, 'ThenBy without OrderBy dies';

@r = Moo::LINQ->Range(1, 5)
    ->Select(sub { -$_ })
    ->OrderBy(sub { $_ })
    ->ToArray();
is_deeply \@r, [-5, -4, -3, -2, -1], 'Select then OrderBy';

@r = Moo::LINQ->From([10, 3, 40, 2, 1, 100])
    ->OrderBy(sub { $_ })
    ->ToArray();
is_deeply \@r, [1, 2, 3, 10, 40, 100], 'OrderBy auto-detects numeric keys';

@r = Moo::LINQ->From([qw(10 3 40 2 1 100)])
    ->OrderBy(sub { $_ }, 'string')
    ->ToArray();
is_deeply \@r, [qw(1 10 100 2 3 40)], 'OrderBy with string type uses cmp';

@r = Moo::LINQ->From([qw(10 3 40 2 1 100)])
    ->OrderBy(sub { $_ }, 'numeric')
    ->ToArray();
is_deeply \@r, [qw(1 2 3 10 40 100)], 'OrderBy with numeric type uses <=>';

done_testing;
