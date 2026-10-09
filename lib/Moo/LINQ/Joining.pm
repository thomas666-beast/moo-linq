package Moo::LINQ::Joining;

use Moo::Role;

our $VERSION = '0.01';

sub Join {
    my ($self, $inner, $outer_key, $inner_key, $result_fn) = @_;
    die "Join requires outer/inner key coderefs and result coderef"
        unless ref $outer_key eq 'CODE'
            && ref $inner_key eq 'CODE'
            && ref $result_fn eq 'CODE';

    my $inner_query = ref $inner eq 'Moo::LINQ'
        ? $inner
        : Moo::LINQ->From($inner);

    # Build hash of inner items keyed by inner_key
    my %inner_by_key;
    my $i_iter = $inner_query->_iterator;
    while (defined(my $i = $i_iter->())) {
        my $k;
        { local $_ = $i; $k = $inner_key->($i); }
        my $ks = defined $k ? "$k" : '__undef__';
        push @{ $inner_by_key{$ks} }, $i;
    }

    my $outer_iter = $self->_iterator;
    my @buffer;

    my $iter = sub {
        while (1) {
            if (@buffer) {
                return shift @buffer;
            }

            my $o = $outer_iter->();
            return undef unless defined $o;

            my $ok;
            { local $_ = $o; $ok = $outer_key->($o); }
            my $oks = defined $ok ? "$ok" : '__undef__';

            my $matches = $inner_by_key{$oks} || [];
            for my $i (@$matches) {
                my $result;
                {
                    local $_ = $o;
                    $result = $result_fn->($o, $i);
                }
                push @buffer, $result;
            }
        }
    };

    return ref($self)->new(_iterator => $iter);
}

sub GroupJoin {
    my ($self, $inner, $outer_key, $inner_key, $result_fn) = @_;
    die "GroupJoin requires outer/inner key coderefs and result coderef"
        unless ref $outer_key eq 'CODE'
            && ref $inner_key eq 'CODE'
            && ref $result_fn eq 'CODE';

    my $inner_query = ref $inner eq 'Moo::LINQ'
        ? $inner
        : Moo::LINQ->From($inner);

    my %inner_by_key;
    my $i_iter = $inner_query->_iterator;
    while (defined(my $i = $i_iter->())) {
        my $k;
        { local $_ = $i; $k = $inner_key->($i); }
        my $ks = defined $k ? "$k" : '__undef__';
        push @{ $inner_by_key{$ks} }, $i;
    }

    my $outer_iter = $self->_iterator;

    my $iter = sub {
        my $o = $outer_iter->();
        return undef unless defined $o;

        my $ok;
        { local $_ = $o; $ok = $outer_key->($o); }
        my $oks = defined $ok ? "$ok" : '__undef__';

        my $matches = $inner_by_key{$oks} || [];
        my $result;
        {
            local $_ = $o;
            $result = $result_fn->($o, $matches);
        }
        return $result;
    };

    return ref($self)->new(_iterator => $iter);
}

sub Zip {
    my ($self, $other, $result_fn) = @_;
    die "Zip requires a coderef" unless ref $result_fn eq 'CODE';

    my $other_query = ref $other eq 'Moo::LINQ'
        ? $other
        : Moo::LINQ->From($other);

    my $a = $self->_iterator;
    my $b = $other_query->_iterator;

    my $iter = sub {
        my $x = $a->();
        return undef unless defined $x;
        my $y = $b->();
        return undef unless defined $y;
        local $_ = $x;
        return $result_fn->($x, $y);
    };

    return ref($self)->new(_iterator => $iter);
}

1;

__END__

=head1 NAME

Moo::LINQ::Joining - Joining operators for Moo::LINQ

=head1 DESCRIPTION

Provides C<Join>, C<GroupJoin>, and C<Zip>. Loaded automatically by L<Moo::LINQ>.

=head1 SEE ALSO

L<Moo::LINQ>

=cut
