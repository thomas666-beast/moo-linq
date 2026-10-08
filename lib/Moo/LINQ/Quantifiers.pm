package Moo::LINQ::Quantifiers;

use Moo::Role;

our $VERSION = '0.01';

# --- Contains: any item equal to $value? ---
sub Contains {
    my ($self, $value) = @_;
    my $iter = $self->_iterator;
    while (defined(my $item = $iter->())) {
        return 1 if defined $value && defined $item && $item eq $value;
        return 1 if !defined $value && !defined $item;
    }
    return 0;
}

# --- SequenceEqual: element-wise equality ---
sub SequenceEqual {
    my ($self, $other) = @_;
    my $other_query = ref $other eq 'Moo::LINQ'
        ? $other
        : Moo::LINQ->From($other);

    my $a = $self->_iterator;
    my $b = $other_query->_iterator;

    while (1) {
        my $x = $a->();
        my $y = $b->();
        my $x_def = defined $x;
        my $y_def = defined $y;

        return 1 if !$x_def && !$y_def;
        return 0 if $x_def != $y_def;
        return 0 if $x ne $y;
    }
}

# --- ElementAt: 0-based index ---
sub ElementAt {
    my ($self, $n) = @_;
    die "ElementAt requires a non-negative integer"
        unless defined $n && $n >= 0;

    my $iter = $self->_iterator;
    my $i = 0;
    while (defined(my $item = $iter->())) {
        return $item if $i == $n;
        $i++;
    }
    die "ElementAt: index $n out of range";
}

sub ElementAtOrDefault {
    my ($self, $n, $default) = @_;
    my $iter = $self->_iterator;
    my $i = 0;
    while (defined(my $item = $iter->())) {
        return $item if $i == $n;
        $i++;
    }
    return $default;
}

# --- Single: exactly one item (optionally matching predicate) ---
sub Single {
    my ($self, $pred) = @_;
    my $iter = $self->_iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        if ($pred) {
            local $_ = $item;
            next unless $pred->($item);
        }
        $found = $item;
        $count++;
        last if $count > 1;
    }

    die "Single: sequence contains no matching element" if $count == 0;
    die "Single: sequence contains more than one matching element"
        if $count > 1;
    return $found;
}

sub SingleOrDefault {
    my ($self, $default, $pred) = @_;
    my $iter = $self->_iterator;
    my $found;
    my $count = 0;

    while (defined(my $item = $iter->())) {
        if ($pred) {
            local $_ = $item;
            next unless $pred->($item);
        }
        $found = $item;
        $count++;
        last if $count > 1;
    }

    return $default if $count == 0;
    die "SingleOrDefault: sequence contains more than one matching element"
        if $count > 1;
    return $found;
}

# --- Last / LastOrDefault ---
sub Last {
    my ($self, $pred) = @_;
    my $iter = $self->_iterator;
    my $found;
    my $seen = 0;

    while (defined(my $item = $iter->())) {
        if ($pred) {
            local $_ = $item;
            next unless $pred->($item);
        }
        $found = $item;
        $seen = 1;
    }

    die "Last: sequence contains no matching element" unless $seen;
    return $found;
}

sub LastOrDefault {
    my ($self, $default, $pred) = @_;
    my $iter = $self->_iterator;
    my $found;
    my $seen = 0;

    while (defined(my $item = $iter->())) {
        if ($pred) {
            local $_ = $item;
            next unless $pred->($item);
        }
        $found = $item;
        $seen = 1;
    }

    return $seen ? $found : $default;
}

# --- DefaultIfEmpty: yield a default when sequence is empty ---
sub DefaultIfEmpty {
    my ($self, $default) = @_;
    $default //= '';

    my $src = $self->_iterator;
    my $emitted = 0;
    my $saw_any = 0;

    my $iter = sub {
        return undef if $emitted;
        my $x = $src->();
        if (defined $x) {
            $saw_any = 1;
            return $x;
        }
        if (!$saw_any) {
            $emitted = 1;
            return $default;
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

1;
