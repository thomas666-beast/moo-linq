requires 'Moo';
requires 'Iterator::Simple';

on 'test' => sub {
    requires 'Test::More';
    requires 'File::Temp';
    requires 'DBI';
    requires 'DBD::SQLite';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::PluginBundle::Basic';
    requires 'Dist::Zilla::Plugin::CopyFilesFromBuild';
    requires 'Dist::Zilla::Plugin::Git::Check';
    requires 'Dist::Zilla::Plugin::Git::Commit';
    requires 'Dist::Zilla::Plugin::Git::NextVersion';
    requires 'Dist::Zilla::Plugin::Git::Push';
    requires 'Dist::Zilla::Plugin::Git::Tag';
    requires 'Dist::Zilla::Plugin::MetaProvides::Package' ;
    requires 'Dist::Zilla::Plugin::MetaResources';
    requires 'Dist::Zilla::Plugin::PodSyntaxTests'; 
    requires 'Dist::Zilla::Plugin::PruneFiles';
    requires 'Dist::Zilla::Plugin::ReadmeFromPod';
    requires 'Dist::Zilla::Plugin::ReadmeMarkdownFromPod';
    requires 'Dist::Zilla::Plugin::Test::Compile';
    requires 'Dist::Zilla::Plugin::Test::ReportPrereqs';
    requires 'Dist::Zilla::Plugin::UploadToCPAN';
    requires 'Dist::Zilla::PluginBundle::Basic';
    requires 'Software::License::Perl_5';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
};
