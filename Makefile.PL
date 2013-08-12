use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Yogafire',
    AUTHOR        => 'toritori0318 <toritori0318@gmail.com>',
    VERSION_FROM  => 'lib/Yogafire.pm',
    PREREQ_PM     => {
        'VM::EC2'                       => '1.23',
        'MouseX::App::Cmd'              => '0',
        'Term::ReadLine'                => '0',
        'Term::ReadLine::Gnu'           => '0',
        'Term::UI'                      => '0',
        'Net::OpenSSH'                  => '0',
        'LWP::UserAgent'                => '0',
        'File::HomeDir'                 => '0',
        'Text::Diff'                    => '0',
        'XML::RSS'                      => '0',
        'YAML::Tiny'                    => '0',
        'DateTime'                      => '0',
        'DateTime::Format::Strptime'    => '0',
        'JSON'                          => '0',
        'Graph::Easy'                   => '0',
        'Parallel::ForkManager'         => '0',
        'Log::Minimal'                  => '0',
        'Template'                      => '0',
        'Text::UnicodeTable::Simple'    => '0',
        'Test::MockObject'              => '0',
        'Test::Mock::Guard'             => '0',
    },
    MIN_PERL_VERSION => '5.008001',
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/yoga' ],
);

