use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Form::Processor::Model::DBIC',
    AUTHOR              => 'Gerda Shank <gs364@cornell.edu>',
    VERSION_FROM        => 'lib/Form/Processor/Model/DBIC.pm',
    ABSTRACT_FROM       => 'lib/Form/Processor/Model/DBIC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Form::Processor' => 0,
        'DBIx::Class'     => 0,
        'Carp'            => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Form-Processor-Model-DBIC-*' },
);
