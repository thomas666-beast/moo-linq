use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Moo::LINQ',
    VERSION_FROM     => 'lib/Moo/LINQ.pm',
    ABSTRACT_FROM    => 'lib/Moo/LINQ.pm',
    AUTHOR           => 'Thomas',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',

    PREREQ_PM => {
        'Moo'              => '2.000',
        'Iterator::Simple' => '0.05',
        'JSON::PP'         => '2.270',
        'Scalar::Util'     => '0',
    },

    TEST_REQUIRES => {
        'Test::More' => '1.300',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },

        provides => {
            'Moo::LINQ' => {
                file    => 'lib/Moo/LINQ.pm',
                version => '0.11',
            },
            'Moo::LINQ::Filtering' => {
                file    => 'lib/Moo/LINQ/Filtering.pm',
                version => '0.02',
            },
            'Moo::LINQ::Projection' => {
                file    => 'lib/Moo/LINQ/Projection.pm',
                version => '0.02',
            },
            'Moo::LINQ::Aggregation' => {
                file    => 'lib/Moo/LINQ/Aggregation.pm',
                version => '0.02',
            },
            'Moo::LINQ::Ordering' => {
                file    => 'lib/Moo/LINQ/Ordering.pm',
                version => '0.04',
            },
            'Moo::LINQ::Grouping' => {
                file    => 'lib/Moo/LINQ/Grouping.pm',
                version => '0.02',
            },
            'Moo::LINQ::Group' => {
                file    => 'lib/Moo/LINQ/Group.pm',
                version => '0.02',
            },
            'Moo::LINQ::Joining' => {
                file    => 'lib/Moo/LINQ/Joining.pm',
                version => '0.01',
            },
            'Moo::LINQ::Sets' => {
                file    => 'lib/Moo/LINQ/Sets.pm',
                version => '0.01',
            },
            'Moo::LINQ::Quantifiers' => {
                file    => 'lib/Moo/LINQ/Quantifiers.pm',
                version => '0.01',
            },
            'Moo::LINQ::Conversion' => {
                file    => 'lib/Moo/LINQ/Conversion.pm',
                version => '0.01',
            },
            'Moo::LINQ::Advanced' => {
                file    => 'lib/Moo/LINQ/Advanced.pm',
                version => '0.01',
            },
        },

        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/you/Moo-LINQ.git',
                web  => 'https://github.com/you/Moo-LINQ',
            },
            bugtracker => {
                web => 'https://github.com/you/Moo-LINQ/issues',
            },
        },
    },
);
