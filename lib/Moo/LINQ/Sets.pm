package Moo::LINQ::Sets;

use Moo::Role;

our $VERSION = '0.01';

sub Concat {
    my ($self, $other) = @_;
    my $other_query = ref $other eq 'Moo::LINQ'
        ? $other
        : Moo::LINQ->From($other);

    my $a = $self->_iterator;
    my $b = $other_query->_iterator;
    my $phase = 0;

    my $iter = sub {
        if ($phase == 0) {
            my $x = $a->();
            return $x if defined $x;
            $phase = 1;
        }
        return $b->();
    };

    return ref($self)->new(_iterator => $iter);
}

sub Union {
    my ($self, $other) = @_;
    return $self->Concat($other)->Distinct();
}

sub Intersect {
    my ($self, $other) = @_;
    my $other_query = ref $other eq 'Moo::LINQ'
        ? $other
        : Moo::LINQ->From($other);

    my %in_other;
    my $b = $other_query->_iterator;
    while (defined(my $y = $b->())) {
        $in_other{ defined $y ? "$y" : '__undef__' } = 1;
    }

    my $a = $self->_iterator;
    my %emitted;
    my $iter = sub {
        while (defined(my $x = $a->())) {
            my $k = defined $x ? "$x" : '__undef__';
            next unless $in_other{$k};
            next if $emitted{$k}++;
            return $x;
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

sub Except {
    my ($self, $other) = @_;
    my $other_query = ref $other eq 'Moo::LINQ'
        ? $other
        : Moo::LINQ->From($other);

    my %in_other;
    my $b = $other_query->_iterator;
    while (defined(my $y = $b->())) {
        $in_other{ defined $y ? "$y" : '__undef__' } = 1;
    }

    my $a = $self->_iterator;
    my %emitted;
    my $iter = sub {
        while (defined(my $x = $a->())) {
            my $k = defined $x ? "$x" : '__undef__';
            next if $in_other{$k};
            next if $emitted{$k}++;
            return $x;
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

1;
