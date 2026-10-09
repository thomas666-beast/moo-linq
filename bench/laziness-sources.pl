#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Benchmark qw(cmpthese timethese);
use File::Temp qw(tempfile);
use Moo::LINQ;

# --- Setup: create a 200k-row CSV ---
my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh "id,name,value\n";
for my $i (1 .. 200_000) {
    print $fh "$i,name_$i," . ($i * 7 % 1000) . "\n";
}
close $fh;

my $fh_open = sub {
    open my $f, '<', $path or die $!;
    return $f;
};

cmpthese(-2, {
    'eager: slurp + grep + map' => sub {
        open my $f, '<', $path or die $!;
        my @rows = <$f>;
        chomp @rows;
        my @parsed;
        for my $line (@rows[1 .. $#rows]) {
            my ($id, $name, $value) = split /,/, $line;
            push @parsed, { id => $id, name => $name, value => $value };
        }
        my @filtered = grep { $_->{value} > 500 } @parsed;
        my @mapped   = map  { $_->{name} } @filtered;
        my $first    = $mapped[0];
    },

    'Moo::LINQ: FromCSV + lazy Take' => sub {
        my $first = Moo::LINQ->FromCSV($path)
            ->Where(sub { $_->{value} > 500 })
            ->Select(sub { $_->{name} })
            ->First();
    },
});

unlink $path;
