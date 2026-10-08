use strict;
use warnings;
use Test::More;
use Moo::LINQ;

is( Moo::LINQ->Range(1, 10)->Count(), 10, 'Count all' );
is( Moo::LINQ->Range(1, 10)->Count(sub { $_ % 2 == 0 }), 5, 'Count with predicate' );
is( Moo::LINQ->Empty()->Count(), 0, 'Count on empty' );

is( Moo::LINQ->Range(1, 10)->Sum(), 55, 'Sum all' );
is( Moo::LINQ->Range(1, 5)->Sum(sub { $_ * 10 }), 150, 'Sum with selector' );
is( Moo::LINQ->Empty()->Sum(), 0, 'Sum on empty is 0' );

is( Moo::LINQ->Range(1, 10)->Average(), 5.5, 'Average' );
is( Moo::LINQ->Range(1, 10)->Average(sub { $_ * 2 }), 11, 'Average with selector' );

my $avg_ok = eval { Moo::LINQ->Empty()->Average(); 1 };
ok( !$avg_ok, 'Average on empty dies' );
like( $@, qr/empty/i, 'Average on empty dies with message' ) if !$avg_ok;

is( Moo::LINQ->Range(3, 9)->Min(), 3, 'Min' );
is( Moo::LINQ->Range(3, 9)->Max(), 9, 'Max' );
is( Moo::LINQ->Range(1, 5)->Min(sub { -$_ }), -5, 'Min with selector' );
is( Moo::LINQ->Range(1, 5)->Max(sub { $_ * 2 }), 10, 'Max with selector' );
ok( !defined Moo::LINQ->Empty()->Min(), 'Min on empty is undef' );
ok( !defined Moo::LINQ->Empty()->Max(), 'Max on empty is undef' );

my $product = Moo::LINQ->Range(1, 5)->Aggregate(1, sub {
    my ($acc, $x) = @_;
    return $acc * $x;
});
is( $product, 120, 'Aggregate computes factorial 5!' );

my $concat = Moo::LINQ->From([qw(a b c)])->Aggregate('', sub {
    my ($acc, $x) = @_;
    return $acc . $x;
});
is( $concat, 'abc', 'Aggregate concatenates' );

done_testing;
