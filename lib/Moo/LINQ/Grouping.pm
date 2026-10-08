package Moo::LINQ::Grouping;

use Moo::Role;
use Moo::LINQ::Group;

our $VERSION = '0.02';

sub GroupBy {
    my ($self, $key_fn, $elem_fn) = @_;
    die "GroupBy requires a coderef" unless ref $key_fn eq 'CODE';

    my %buckets;
    my @order;
    my $iter = $self->_iterator;

    while (defined(my $item = $iter->())) {
        my $key;
        { local $_ = $item; $key = $key_fn->($item); }

        my $key_s = defined $key ? "$key" : '__undef__';
        if (!exists $buckets{$key_s}) {
            $buckets{$key_s} = { key => $key, items => [] };
            push @order, $key_s;
        }

        my $elem = $item;
        if ($elem_fn) {
            die "GroupBy element selector must be a coderef"
                unless ref $elem_fn eq 'CODE';
            { local $_ = $item; $elem = $elem_fn->($item); }
        }

        push @{ $buckets{$key_s}{items} }, $elem;
    }

    my @groups = map {
        my $b = $buckets{$_};
        Moo::LINQ::Group->new(key => $b->{key}, items => $b->{items});
    } @order;

    my $i = 0;
    my $out = sub { return $i < @groups ? $groups[$i++] : undef };
    return ref($self)->new(_iterator => $out);
}

sub ToLookup {
    my ($self, $key_fn, $elem_fn) = @_;
    my $grouped = $self->GroupBy($key_fn, $elem_fn);
    my %lookup;
    my $iter = $grouped->_iterator;
    while (defined(my $g = $iter->())) {
        my $key_s = defined $g->key ? "$g->{key}" : '__undef__';
        $lookup{$key_s} = $g;
    }
    return \%lookup;
}

1;
