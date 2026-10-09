use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Moo::LINQ;

# --- FromLines ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.txt', UNLINK => 1);
    print $fh "alpha\nbeta\n\ngamma\n";
    close $fh;

    my @r = Moo::LINQ->FromLines($path)->ToArray();
    is_deeply \@r, [qw(alpha beta gamma)], 'FromLines chomps and skips blanks';
}

{
    my ($fh, $path) = tempfile(SUFFIX => '.txt', UNLINK => 1);
    print $fh "x\ny\n";
    close $fh;

    my @r = Moo::LINQ->FromLines($path, chomp => 0)->ToArray();
    is scalar @r, 2, 'FromLines chomp=0 keeps newlines';
    like $r[0], qr/\n$/, 'chomp=0 keeps trailing newline';
}

# --- FromCSV with header ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh "name,age\nAlice,30\nBob,25\n";
    close $fh;

    my @r = Moo::LINQ->FromCSV($path)->ToArray();
    is scalar @r, 2, 'FromCSV header yields 2 rows';
    is $r[0]{name}, 'Alice', 'FromCSV header field';
    is $r[0]{age},  '30',    'FromCSV header field';
    is $r[1]{name}, 'Bob',   'FromCSV second row';
}

# --- FromCSV without header ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh "a,b,c\n1,2,3\n";
    close $fh;

    my @r = Moo::LINQ->FromCSV($path, header => 0)->ToArray();
    is scalar @r, 2, 'FromCSV no header yields 2 rows';
    is_deeply $r[0], [qw(a b c)], 'FromCSV no header returns arrayrefs';
}

# --- FromCSV with quoted field containing comma ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh qq{name,note\nAlice,"Hello, world"\n};
    close $fh;

    my @r = Moo::LINQ->FromCSV($path)->ToArray();
    is $r[0]{note}, 'Hello, world', 'FromCSV handles quoted comma';
}

# --- FromCSV with quoted field containing doubled quotes ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh qq{name,quote\nAlice,"She said ""hi"""\n};
    close $fh;

    my @r = Moo::LINQ->FromCSV($path)->ToArray();
    is $r[0]{quote}, 'She said "hi"', 'FromCSV handles doubled quotes';
}

# --- FromTSV ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.tsv', UNLINK => 1);
    print $fh "name\tage\nAlice\t30\nBob\t25\n";
    close $fh;

    my @r = Moo::LINQ->FromTSV($path)->ToArray();
    is $r[0]{name}, 'Alice', 'FromTSV field';
    is $r[0]{age},  '30',    'FromTSV field';
}

# --- Laziness: FromCSV on a big file stops early ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh "n\n";
    print $fh "$_\n" for 1 .. 100_000;
    close $fh;

    my $first = Moo::LINQ->FromCSV($path)->First();
    is $first->{n}, '1', 'FromCSV First() returns first row without reading all';

    my @take3 = Moo::LINQ->FromCSV($path)->Take(3)->ToArray();
    is scalar @take3, 3, 'FromCSV Take(3)';
    is_deeply [ map { $_->{n} } @take3 ], [qw(1 2 3)],
        'FromCSV Take(3) values';
}

# --- Real pipeline: CSV -> Filter -> Sort -> Select ---
{
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh "name,salary\nAlice,120\nBob,90\nCarol,130\nDave,80\n";
    close $fh;

    my @top = Moo::LINQ->FromCSV($path)
        ->Where(sub { $_->{salary} > 85 })
        ->OrderByDescending(sub { $_->{salary} }, 'numeric')
        ->Select(sub { "$_->{name}($_->{salary})" })
        ->ToArray();

    is_deeply \@top, [qw(Carol(130) Alice(120) Bob(90))],
        'FromCSV pipeline with filter, sort, select';
}

done_testing;
