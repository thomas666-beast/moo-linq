use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Moo::LINQ',
    VERSION_FROM     => 'lib/Moo/LINQ.pm',
    ABSTRACT_FROM    => 'lib/Moo/LINQ.pm',
    AUTHOR           => 'Your Name <you@example.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    PREREQ_PM        => {
        'Moo'              => 0,
        'Iterator::Simple' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/you/Moo-LINQ.git',
                web  => 'https://github.com/you/Moo-LINQ',
            },
        },
    },
);
