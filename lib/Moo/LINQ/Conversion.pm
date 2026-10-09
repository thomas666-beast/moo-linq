package Moo::LINQ::Conversion;

use Moo::Role;
use JSON::PP ();

our $VERSION = '0.01';

# --- ToHash: key_fn => item, or key_fn => elem_fn ---
sub ToHash {
    my ($self, $key_fn, $elem_fn) = @_;
    die "ToHash requires a key selector coderef"
        unless ref $key_fn eq 'CODE';

    my %out;
    my $iter = $self->_iterator;
    while (defined(my $item = $iter->())) {
        my $key;
        { local $_ = $item; $key = $key_fn->($item); }

        my $val = $item;
        if ($elem_fn) {
            die "ToHash element selector must be a coderef"
                unless ref $elem_fn eq 'CODE';
            { local $_ = $item; $val = $elem_fn->($item); }
        }

        $out{$key} = $val;
    }
    return \%out;
}

# --- ToJson: serialize the sequence to JSON ---
sub ToJson {
    my $self = shift;
    my @items = $self->ToArray;
    return JSON::PP->new->canonical->encode(\@items);
}

# --- ToString: join items with a separator ---
sub ToString {
    my ($self, $sep) = @_;
    $sep = ', ' unless defined $sep;
    my @items = $self->ToArray;
    return join $sep, map { defined $_ ? $_ : '' } @items;
}

# --- ForEach: side-effect terminal (like .NET's List.ForEach) ---
sub ForEach {
    my ($self, $fn) = @_;
    die "ForEach requires a coderef" unless ref $fn eq 'CODE';
    my $iter = $self->_iterator;
    my $i = 0;
    while (defined(my $item = $iter->())) {
        local $_ = $item;
        $fn->($item, $i);
        $i++;
    }
    return;
}

# --- Print: convenience terminal ---
sub Print {
    my ($self, $sep) = @_;
    $sep = "\n" unless defined $sep;
    print $self->ToString($sep), "\n";
    return;
}

1;

__END__

=head1 NAME

Moo::LINQ::Conversion - Conversion operators for Moo::LINQ

=head1 DESCRIPTION

Provides C<ToHash>, C<ToJson>, C<ToString>, C<ForEach>, and C<Print>.
Loaded automatically by L<Moo::LINQ>.

=head1 SEE ALSO

L<Moo::LINQ>

=cut
