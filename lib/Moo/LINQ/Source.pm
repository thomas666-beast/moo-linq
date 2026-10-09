package Moo::LINQ::Source;

# ABSTRACT: File-based data sources for Moo::LINQ

use Moo::Role;
use strict;
use warnings;

use Moo::LINQ::Source::Lines;
use Moo::LINQ::Source::CSV;
use Moo::LINQ::Source::TSV;

sub FromLines {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::Lines->new(
        path => $path,
        %opts,
    );
    return $class->new(_iterator => $src->iterator);
}

sub FromCSV {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::CSV->new(
        path => $path,
        %opts,
    );
    return $class->new(_iterator => $src->iterator);
}

sub FromTSV {
    my ($class, $path, %opts) = @_;
    my $src = Moo::LINQ::Source::TSV->new(
        path => $path,
        %opts,
    );
    return $class->new(_iterator => $src->iterator);
}

1;
