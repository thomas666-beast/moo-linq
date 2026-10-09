package Moo::LINQ::Source::JSON;

# ABSTRACT: JSON array source for Moo::LINQ

use Moo;
use strict;
use warnings;
use JSON::PP ();

has path    => (is => 'ro', required => 1);
has _data   => (is => 'ro', lazy => 1, builder => '_build_data');

sub _build_data {
    my $self = shift;

    open my $fh, '<', $self->path
        or die "Cannot open '$self->{path}': $!";
    local $/;
    my $raw = <$fh>;
    close $fh;

    my $decoded = eval { JSON::PP->new->utf8->decode($raw) };
    die "JSON parse error in '$self->{path}': $@" if $@;

    if (ref $decoded ne 'ARRAY') {
        die "Top-level JSON in '$self->{path}' must be an array, got "
            . ref($decoded);
    }

    return $decoded;
}

sub iterator {
    my $self = shift;
    my $data = $self->_data;
    my $i    = 0;

    return sub {
        return undef if $i >= @$data;
        return $data->[ $i++ ];
    };
}

1;

__END__

=head1 NAME

Moo::LINQ::Source::JSON - JSON array source for Moo::LINQ

=head1 SYNOPSIS

    my @users = Moo::LINQ->FromJSON('users.json')
        ->Where(sub { $_->{age} > 30 })
        ->OrderBy(sub { $_->{name} })
        ->ToArray();

=head1 DESCRIPTION

Reads a JSON file whose top-level value is an array, and yields its
elements lazily. Non-array top-level values cause a fatal error.

Uses L<JSON::PP> (core since Perl 5.14), so no extra dependencies are
required.

=head1 NOTES

The whole file is decoded up front — JSON is not a streaming format by
default. For very large JSON files, pre-process them with C<jq> or a
streaming parser into LTSV, CSV, or JSON-lines format, then feed them
through L<Moo::LINQ::Source::LTSV>, L<Moo::LINQ::Source::CSV>, or
L<Moo::LINQ::Source::Lines>.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>

=cut
