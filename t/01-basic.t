use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# From array
my @result = Moo::LINQ->From([1, 2, 3, 4, 5])->ToArray();
is_deeply \@result, [1, 2, 3, 4, 5], 'From array works';

# Range with default step
@result = Moo::LINQ->Range(1, 5)->ToArray();
is_deeply \@result, [1, 2, 3, 4, 5], 'Range default step works';

# Range with custom step
@result = Moo::LINQ->Range(1, 10, 2)->ToArray();
is_deeply \@result, [1, 3, 5, 7, 9], 'Range with step works';

# Empty
@result = Moo::LINQ->Empty()->ToArray();
is_deeply \@result, [], 'Empty works';

# From coderef (generator)
my $i = 0;
my @gen = Moo::LINQ->From(sub { return $i < 3 ? $i++ : undef })->ToArray();
is_deeply \@gen, [0, 1, 2], 'From coderef works';

# ToList (returns arrayref)
my $list = Moo::LINQ->From([10, 20])->ToList();
is_deeply $list, [10, 20], 'ToList returns arrayref';

done_testing;
