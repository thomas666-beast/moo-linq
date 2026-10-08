use strict;
use warnings;
use Test::More;
use Moo::LINQ;

my @people = (
    { name => 'Alice', dept => 'Eng' },
    { name => 'Bob',   dept => 'Sales' },
    { name => 'Carol', dept => 'Eng' },
    { name => 'Dave',  dept => 'Sales' },
    { name => 'Eve',   dept => 'HR' },
);

my @groups = Moo::LINQ->From(\@people)
    ->GroupBy(sub { $_->{dept} })
    ->ToArray();

is scalar @groups, 3, 'GroupBy produces 3 groups';

my %by_key = map { $_->key => $_ } @groups;
is $by_key{Eng}->Count, 2, 'Eng group has 2';
is $by_key{Sales}->Count, 2, 'Sales group has 2';
is $by_key{HR}->Count, 1, 'HR group has 1';

my @eng_names = map { $_->{name} } $by_key{Eng}->ToArray;
is_deeply \@eng_names, [qw(Alice Carol)], 'Eng group names';

# GroupBy with element selector
my @groups2 = Moo::LINQ->From(\@people)
    ->GroupBy(sub { $_->{dept} }, sub { $_->{name} })
    ->ToArray();
my %by_key2 = map { $_->key => $_ } @groups2;
is_deeply [ $by_key2{Eng}->ToArray ], [qw(Alice Carol)],
    'GroupBy with element selector';

# ToLookup
my $lookup = Moo::LINQ->From(\@people)
    ->ToLookup(sub { $_->{dept} });
is scalar keys %$lookup, 3, 'ToLookup has 3 keys';
is $lookup->{Eng}->Count, 2, 'Lookup Eng count';

# GroupBy then aggregate
my @counts = Moo::LINQ->From(\@people)
    ->GroupBy(sub { $_->{dept} })
    ->Select(sub { $_->key . ':' . $_->Count })
    ->ToArray();
is_deeply [ sort @counts ], [qw(Eng:2 HR:1 Sales:2)],
    'GroupBy then Select for counts';

done_testing;
