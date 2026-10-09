use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);
use Moo::LINQ;

# Skip all tests if DBI or DBD::SQLite are unavailable.
BEGIN {
    eval { require DBI;           DBI->import;           1 }
        or plan skip_all => 'DBI required for SQLite tests';
    eval { require DBD::SQLite;   DBD::SQLite->import;   1 }
        or plan skip_all => 'DBD::SQLite required for SQLite tests';
}

# --- Helper: create a test database ---
sub make_db {
    my ($rows) = @_;

    my ($fh, $path) = tempfile(SUFFIX => '.db', UNLINK => 1);
    close $fh;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '',
        { RaiseError => 1, AutoCommit => 1 });

    $dbh->do(<<'SQL');
CREATE TABLE users (
    id     INTEGER PRIMARY KEY,
    name   TEXT,
    age    INTEGER,
    dept   TEXT
)
SQL

    my $sth = $dbh->prepare(
        'INSERT INTO users (id, name, age, dept) VALUES (?, ?, ?, ?)');
    for my $r (@$rows) {
        $sth->execute(@$r);
    }
    $sth->finish;
    $dbh->disconnect;

    return $path;
}

# --- Basic query ---
{
    my $path = make_db([
        [1, 'Alice', 30, 'Eng'],
        [2, 'Bob',   25, 'Sales'],
        [3, 'Carol', 35, 'Eng'],
    ]);

    my @rows = Moo::LINQ->FromSQLite($path, 'SELECT * FROM users')->ToArray();
    is scalar @rows, 3, 'FromSQLite yields 3 rows';
    is $rows[0]{name}, 'Alice', 'First row name';
    is $rows[2]{dept}, 'Eng',   'Third row dept';
}

# --- Pipeline ---
{
    my $path = make_db([
        [1, 'Alice', 30, 'Eng'],
        [2, 'Bob',   25, 'Sales'],
        [3, 'Carol', 35, 'Eng'],
        [4, 'Dave',  40, 'Sales'],
    ]);

    my @names = Moo::LINQ->FromSQLite($path, 'SELECT * FROM users')
        ->Where(sub { $_->{age} > 30 })
        ->OrderBy(sub { $_->{age} })
        ->Select(sub { $_->{name} })
        ->ToArray();

    is_deeply \@names, [qw(Carol Dave)], 'FromSQLite pipeline';
}

# --- Bind parameters ---
{
    my $path = make_db([
        [1, 'Alice', 30, 'Eng'],
        [2, 'Bob',   25, 'Sales'],
        [3, 'Carol', 35, 'Eng'],
    ]);

    my @rows = Moo::LINQ->FromSQLite(
        $path,
        'SELECT * FROM users WHERE dept = ?',
        ['Eng'],
    )->ToArray();

    is scalar @rows, 2, 'FromSQLite with bind parameter';
    is_deeply [ map { $_->{name} } @rows ], [qw(Alice Carol)],
        'Bind parameter filters correctly';
}

# --- Aggregation over streamed rows ---
{
    my $path = make_db([
        [1, 'Alice', 30, 'Eng'],
        [2, 'Bob',   25, 'Sales'],
        [3, 'Carol', 35, 'Eng'],
        [4, 'Dave',  40, 'Sales'],
    ]);

    my $avg_eng = Moo::LINQ->FromSQLite(
        $path,
        "SELECT * FROM users WHERE dept = 'Eng'",
    )->Average(sub { $_->{age} });

    is $avg_eng, 32.5, 'Average over SQLite result';
}

# --- Laziness: Take stops early ---
{
    my @many = map { [$_, "user$_", 20 + $_, 'Eng'] } 1 .. 10_000;
    my $path = make_db(\@many);

    my @take3 = Moo::LINQ->FromSQLite($path, 'SELECT * FROM users')
        ->Take(3)
        ->ToArray();

    is scalar @take3, 3, 'Take(3) over SQLite';
    is_deeply [ map { $_->{name} } @take3 ], [qw(user1 user2 user3)],
        'Take(3) values';
}

# --- ORDER BY in SQL ---
{
    my $path = make_db([
        [1, 'Zoe',  30, 'Eng'],
        [2, 'Amy',  25, 'Eng'],
        [3, 'Mike', 35, 'Eng'],
    ]);

    my @names = Moo::LINQ->FromSQLite(
        $path,
        'SELECT * FROM users ORDER BY name',
    )->Select(sub { $_->{name} })->ToArray();

    is_deeply \@names, [qw(Amy Mike Zoe)], 'SQL ORDER BY respected';
}

# --- Integration: join in SQL, shape in Perl ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.db', UNLINK => 1);
    close $fh;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$path", '', '',
        { RaiseError => 1, AutoCommit => 1 });
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE orders (id INTEGER PRIMARY KEY, user_id INTEGER, amount INTEGER)');
    $dbh->do("INSERT INTO users (id, name) VALUES (1, 'Alice'), (2, 'Bob')");
    $dbh->do("INSERT INTO orders (user_id, amount) VALUES (1, 100), (1, 200), (2, 50)");
    $dbh->disconnect;

    my $sql = <<'SQL';
SELECT u.name AS name, o.amount AS amount
FROM users u
JOIN orders o ON o.user_id = u.id
SQL

    my $groups = Moo::LINQ->FromSQLite($path, $sql)
        ->GroupBy(sub { $_->{name} });

    my %totals;
    my $gi = $groups->_iterator;
    while (defined(my $g = $gi->())) {
        my $key   = $g->key;
        my $total = $g->AsQuery->Sum(sub { $_->{amount} });
        $totals{$key} = $total;
    }

    is_deeply \%totals, { Alice => 300, Bob => 50 },
        'SQL JOIN + LINQ GroupBy + explicit aggregate loop';
}

done_testing;
