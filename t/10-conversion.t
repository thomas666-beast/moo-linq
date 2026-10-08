use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- ToHash ---
my @people = (
    { id => 1, name => 'Alice' },
    { id => 2, name => 'Bob' },
    { id => 3, name => 'Carol' },
);
my $by_id = Moo::LINQ->From(\@people)->ToHash(
    sub { $_->{id} },
    sub { $_->{name} },
);
is_deeply $by_id, { 1 => 'Alice', 2 => 'Bob', 3 => 'Carol' },
    'ToHash with key and element selectors';

my $whole = Moo::LINQ->From(\@people)->ToHash(sub { $_->{id} });
is $whole->{2}{name}, 'Bob', 'ToHash without element selector stores item';

# --- ToJson ---
my $json = Moo::LINQ->Range(1, 3)->ToJson();
is $json, '[1,2,3]', 'ToJson';

# --- ToString ---
is( Moo::LINQ->From([qw(a b c)])->ToString('-'), 'a-b-c', 'ToString with sep' );
is( Moo::LINQ->From([qw(a b c)])->ToString(), 'a, b, c', 'ToString default sep' );

# --- ForEach ---
my @collected;
Moo::LINQ->Range(1, 3)->ForEach(sub {
    my ($item, $i) = @_;
    push @collected, "$i:$item";
});
is_deeply \@collected, [qw(0:1 1:2 2:3)], 'ForEach iterates with index';

# --- Real pipeline: group, count, convert ---
my @orders = (
    { customer => 'Alice', amount => 10 },
    { customer => 'Bob',   amount => 20 },
    { customer => 'Alice', amount => 30 },
    { customer => 'Carol', amount => 40 },
);
my $totals = Moo::LINQ->From(\@orders)
    ->GroupBy(sub { $_->{customer} })
    ->Select(sub {
        my $g = $_;
        [ $g->key, $g->AsQuery->Sum(sub { $_->{amount} }) ];
    })
    ->ToHash(sub { $_->[0] }, sub { $_->[1] });
is_deeply $totals, { Alice => 40, Bob => 20, Carol => 40 },
    'Real pipeline: GroupBy -> Sum -> ToHash';

done_testing;
