#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(cmpthese);
use File::Temp qw(tempfile);
use Moo::LINQ;

require DBI;
require DBD::SQLite;

# --- Setup: a 100k-row SQLite database ---
my ($fh, $path) = tempfile(SUFFIX => '.db', UNLINK => 1);
close $fh;

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '',
        { RaiseError => 1, AutoCommit => 1 });
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)');
    my $sth = $dbh->prepare('INSERT INTO users (name, age) VALUES (?, ?)');
    $dbh->begin_work;
    for my $i (1 .. 100_000) {
        $sth->execute("user_$i", 20 + ($i % 50));
    }
    $dbh->commit;
    $sth->finish;
    $dbh->disconnect;
}

cmpthese(-2, {
    'eager: DBI fetchall_hashref' => sub {
        my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '',
            { RaiseError => 1 });
        my $rows = $dbh->selectall_arrayref(
            'SELECT * FROM users WHERE age > 60',
            { Slice => {} });
        my $first = $rows->[0];
        $dbh->disconnect;
    },

    'Moo::LINQ: FromSQLite + First' => sub {
        my $first = Moo::LINQ->FromSQLite(
            $path,
            'SELECT * FROM users WHERE age > 60',
        )->First();
    },
});

unlink $path;
