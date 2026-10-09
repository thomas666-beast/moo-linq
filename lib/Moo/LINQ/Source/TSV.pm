package Moo::LINQ::Source::TSV;

# ABSTRACT: TSV file source for Moo::LINQ

use Moo;
use strict;
use warnings;
extends 'Moo::LINQ::Source::CSV';

has '+delimiter' => (default => sub { "\t" });

1;
