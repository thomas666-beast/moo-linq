package Moo::LINQ::Source::TSV;

# ABSTRACT: TSV file source for Moo::LINQ

use Moo;
use strict;
use warnings;
extends 'Moo::LINQ::Source::CSV';

has '+delimiter' => (default => sub { "\t" });

1;

__END__

=head1 NAME

Moo::LINQ::Source::TSV - TSV file source for Moo::LINQ

=head1 DESCRIPTION

Streaming TSV reader. A thin subclass of L<Moo::LINQ::Source::CSV> with
the delimiter defaulted to a tab. Used through C<Moo::LINQ->FromTSV>.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>, L<Moo::LINQ::Source::CSV>

=cut
