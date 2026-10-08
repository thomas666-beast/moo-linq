use strict;
use warnings;
use Test::More;
use Moo::LINQ;

my @customers = (
    { id => 1, name => 'Alice' },
    { id => 2, name => 'Bob' },
    { id => 3, name => 'Carol' },
);
my @orders = (
    { customer_id => 1, product => 'Widget' },
    { customer_id => 2, product => 'Gadget' },
    { customer_id => 1, product => 'Doohickey' },
    { customer_id => 4, product => 'Orphan' },
);

# --- Join ---
my @joined = Moo::LINQ->From(\@customers)
    ->Join(
        \@orders,
        sub { $_->{id} },
        sub { $_->{customer_id} },
        sub { my ($c, $o) = @_; "$c->{name}:$o->{product}" },
    )
    ->ToArray();
is_deeply [ sort @joined ], [qw(Alice:Doohickey Alice:Widget Bob:Gadget)],
    'Join matches customers to orders';

# --- GroupJoin ---
my @grouped = Moo::LINQ->From(\@customers)
    ->GroupJoin(
        \@orders,
        sub { $_->{id} },
        sub { $_->{customer_id} },
        sub {
            my ($c, $orders) = @_;
            return $c->{name} . ':' . scalar(@$orders);
        },
    )
    ->ToArray();
is_deeply \@grouped, [qw(Alice:2 Bob:1 Carol:0)],
    'GroupJoin includes customers with no orders';

# --- Zip ---
my @zipped = Moo::LINQ->From([1, 2, 3])
    ->Zip([qw(a b c d)], sub { "$_[0]$_[1]" })
    ->ToArray();
is_deeply \@zipped, [qw(1a 2b 3c)], 'Zip stops at shorter sequence';

done_testing;
