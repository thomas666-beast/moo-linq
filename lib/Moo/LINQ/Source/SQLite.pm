package Moo::LINQ::Source::SQLite;

# ABSTRACT: SQLite query source for Moo::LINQ

use Moo;
use strict;
use warnings;

has path    => (is => 'ro', required => 1);
has query   => (is => 'ro', required => 1);
has params  => (is => 'ro', default  => sub { [] });
has dbh     => (is => 'ro', lazy => 1, builder => '_build_dbh');
has sth     => (is => 'ro', lazy => 1, builder => '_build_sth');

sub _build_dbh {
    my $self = shift;

    # Lazy-load DBI and DBD::SQLite only when this source is actually used.
    require DBI;
    DBI->import;

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$self->{path}",
        '', '',
        {
            RaiseError => 1,
            AutoCommit => 1,
            PrintError => 0,
            sqlite_see_if_its_a_number => 1,
        },
    ) or die "Cannot open SQLite database '$self->{path}': $DBI::errstr";

    return $dbh;
}

sub _build_sth {
    my $self = shift;
    my $sth  = $self->dbh->prepare($self->query);
    $sth->execute(@{ $self->params });
    return $sth;
}

sub iterator {
    my $self = shift;

    # Force the statement handle to be built now, so we fail fast if the
    # query is invalid.
    $self->sth;

    # The closure captures $self, keeping the source object (and its
    # dbh/sth) alive until the iterator itself is garbage-collected.
    return sub {
        my $row = $self->sth->fetchrow_hashref;
        return undef unless defined $row;
        return $row;
    };
}

sub DEMOLISH {
    my $self = shift;
    if ($self->{sth}) {
        eval { $self->{sth}->finish };
    }
    if ($self->{dbh}) {
        eval { $self->{dbh}->disconnect };
    }
    return;
}

1;

__END__

=head1 NAME

Moo::LINQ::Source::SQLite - SQLite query source for Moo::LINQ

=head1 SYNOPSIS

    use Moo::LINQ;

    my @rows = Moo::LINQ->FromSQLite('app.db', 'SELECT * FROM users')
        ->Where(sub { $_->{age} > 30 })
        ->OrderBy(sub { $_->{name} })
        ->Take(10)
        ->ToArray();

    my @active = Moo::LINQ->FromSQLite(
        'app.db',
        'SELECT * FROM users WHERE status = ?',
        ['active'],
    )->ToArray();

=head1 DESCRIPTION

Streams rows from a SQLite query as hashrefs. The statement handle is
executed lazily on first use and iterated one row at a time — the full
result set is never buffered.

=head1 OPTIONS

=over 4

=item * C<path> (required) — path to the SQLite database file

=item * C<query> (required) — SQL SELECT statement

=item * C<params> (optional) — arrayref of bind values, default C<[]>

=back

=head1 REQUIREMENTS

Requires L<DBI> and L<DBD::SQLite>. These are only loaded when
C<FromSQLite> is actually called — libraries that use Moo::LINQ without
SQLite support do not need them installed.

=head1 RESOURCE CLEANUP

The database handle and statement handle are closed when the last
reference to the Moo::LINQ object goes out of scope. To release
resources earlier, ensure no references to the query remain and call
C<undef>.

=head1 SEE ALSO

L<Moo::LINQ>, L<Moo::LINQ::Source>, L<DBI>, L<DBD::SQLite>

=cut
