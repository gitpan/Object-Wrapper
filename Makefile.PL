use 5.8.0;
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME	=> "Object::Wrapper",

    # Note: this will usually go up with the version
    # of Parallel::Depend but may change due to 
    # documentation or ::Util updates.

    VERSION         => 0.05,
    ABSTRACT_FROM   => './lib/Object/Wrapper.pm',

	AUTHOR     	=> 'Steven Lembark <lembark@wrkhors.com>',
	PREREQ_PM	=> 
	{
        # core modules: whatever came with perl
        # should be usable

        if              => 0,
        strict          => 0,

        Scalar::Util    => 0,
        Symbol          => 0,
        Carp            => 0,

        parent          => 0.2,
	},
);
