use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Moo::LINQ;

# --- FromLTSV: basic ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.ltsv', UNLINK => 1);
    print $fh "host:10.0.0.1\tstatus:200\tbytes:1200\n";
    print $fh "host:10.0.0.2\tstatus:404\tbytes:500\n";
    print $fh "host:10.0.0.1\tstatus:200\tbytes:800\n";
    close $fh;

    my @r = Moo::LINQ->FromLTSV($path)->ToArray();
    is scalar @r, 3, 'FromLTSV yields 3 records';
    is $r[0]{host}, '10.0.0.1', 'FromLTSV field host';
    is $r[0]{status}, '200',    'FromLTSV field status';
    is $r[1]{status}, '404',    'FromLTSV field on second record';
}

# --- FromLTSV: missing fields are simply absent ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.ltsv', UNLINK => 1);
    print $fh "a:1\tb:2\n";
    print $fh "a:3\n";
    close $fh;

    my @r = Moo::LINQ->FromLTSV($path)->ToArray();
    is $r[0]{b}, '2',  'FromLTSV first record has b';
    ok !exists $r[1]{b}, 'FromLTSV second record has no b';
}

# --- FromLTSV: value containing colon ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.ltsv', UNLINK => 1);
    print $fh "time:12:34:56\tmsg:hello\n";
    close $fh;

    my @r = Moo::LINQ->FromLTSV($path)->ToArray();
    is $r[0]{time}, '12:34:56', 'FromLTSV preserves colons in values';
}

# --- FromLTSV: lazy ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.ltsv', UNLINK => 1);
    print $fh "n:$_\n" for 1 .. 100_000;
    close $fh;

    my $first = Moo::LINQ->FromLTSV($path)->First();
    is $first->{n}, '1', 'FromLTSV First() is lazy';

    my @take3 = Moo::LINQ->FromLTSV($path)->Take(3)->ToArray();
    is_deeply [ map { $_->{n} } @take3 ], [qw(1 2 3)],
        'FromLTSV Take(3)';
}

# --- FromLTSV: real pipeline ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.ltsv', UNLINK => 1);
    print $fh "host:10.0.0.1\tstatus:200\tbytes:1200\n";
    print $fh "host:10.0.0.2\tstatus:404\tbytes:500\n";
    print $fh "host:10.0.0.1\tstatus:200\tbytes:800\n";
    print $fh "host:10.0.0.3\tstatus:200\tbytes:3200\n";
    close $fh;

    my $total = Moo::LINQ->FromLTSV($path)
        ->Where(sub { $_->{status} eq '200' })
        ->Sum(sub { $_->{bytes} });
    is $total, 5200, 'FromLTSV -> Where -> Sum pipeline';

    my @hosts = Moo::LINQ->FromLTSV($path)
        ->Where(sub { $_->{status} eq '200' })
        ->DistinctBy(sub { $_->{host} })
        ->Select(sub { $_->{host} })
        ->ToArray();
    is_deeply \@hosts, [qw(10.0.0.1 10.0.0.3)],
        'FromLTSV -> DistinctBy -> Select';
}

# --- FromJSON: basic array ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
    print $fh '[{"name":"Alice","age":30},{"name":"Bob","age":25}]';
    close $fh;

    my @r = Moo::LINQ->FromJSON($path)->ToArray();
    is scalar @r, 2, 'FromJSON yields 2 records';
    is $r[0]{name}, 'Alice', 'FromJSON field';
    is $r[1]{age},  25,      'FromJSON numeric field';
}

# --- FromJSON: pipeline ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
    print $fh '[{"n":3},{"n":1},{"n":4},{"n":1},{"n":5},{"n":9},{"n":2},{"n":6}]';
    close $fh;

    my @sorted = Moo::LINQ->FromJSON($path)
        ->Select(sub { $_->{n} })
        ->OrderBy(sub { $_ })
        ->Distinct()
        ->ToArray();
    is_deeply \@sorted, [1, 2, 3, 4, 5, 6, 9],
        'FromJSON -> Select -> OrderBy -> Distinct';
}

# --- FromJSON: non-array top-level dies ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
    print $fh '{"a":1}';
    close $fh;

    my $died = !eval { Moo::LINQ->FromJSON($path)->ToArray(); 1 };
    ok $died, 'FromJSON dies on non-array top-level';
    like $@, qr/must be an array/, 'FromJSON error message';
}

# --- FromJSON: malformed JSON dies ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
    print $fh '[{"a": }]';
    close $fh;

    my $died = !eval { Moo::LINQ->FromJSON($path)->ToArray(); 1 };
    ok $died, 'FromJSON dies on malformed JSON';
}

done_testing;
