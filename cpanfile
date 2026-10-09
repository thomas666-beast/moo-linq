requires 'Moo';
requires 'Iterator::Simple';

on 'test' => sub {
    requires 'Test::More';
    requires 'File::Temp';
    requires 'DBI';
    requires 'DBD::SQLite';
};
