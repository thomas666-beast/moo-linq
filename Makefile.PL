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

    # ------------------------------------------------------------------
    # Runtime dependencies: what a user needs to *use* Moo::LINQ
    # ------------------------------------------------------------------
    PREREQ_PM => {
        'Moo'              => '2.000',
        'Iterator::Simple' => '0.05',
        'JSON::PP'         => '2.270',
        'Scalar::Util'     => '0',
    },

    # ------------------------------------------------------------------
    # Test dependencies: what runs during `make test` after install
    # ------------------------------------------------------------------
    TEST_REQUIRES => {
        'Test::More'  => '1.300',
        'File::Temp'  => '0.22',
        # DBI + DBD::SQLite are only needed by t/14-source-sqlite.t.
        # The test file skips itself if they are missing, so they are
        # listed here but NOT as hard runtime prerequisites.
        'DBI'         => '1.600',
        'DBD::SQLite' => '1.60',
    },

    # ------------------------------------------------------------------
    # Extra metadata for META.json / META.yml
    # ------------------------------------------------------------------
    META_MERGE => {
        'meta-spec' => { version => 2 },

        # Optional features: not required for basic use
        optional_features => {
            sqlite => {
                description => 'Stream SQLite queries via FromSQLite',
                requires    => {
                    'DBI'         => '1.600',
                    'DBD::SQLite' => '1.60',
                },
            },
        },

        # Every module provided by this distribution
        provides => {
            'Moo::LINQ' => {
                file    => 'lib/Moo/LINQ.pm',
                version => '0.12',
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
            'Moo::LINQ::Source' => {
                file    => 'lib/Moo/LINQ/Source.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::Lines' => {
                file    => 'lib/Moo/LINQ/Source/Lines.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::CSV' => {
                file    => 'lib/Moo/LINQ/Source/CSV.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::TSV' => {
                file    => 'lib/Moo/LINQ/Source/TSV.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::LTSV' => {
                file    => 'lib/Moo/LINQ/Source/LTSV.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::JSON' => {
                file    => 'lib/Moo/LINQ/Source/JSON.pm',
                version => '0.01',
            },
            'Moo::LINQ::Source::SQLite' => {
                file    => 'lib/Moo/LINQ/Source/SQLite.pm',
                version => '0.01',
            },
        },

        # Links shown on MetaCPAN
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
