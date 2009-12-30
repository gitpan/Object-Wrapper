
package Testify;

use v5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use base qw( Object::Wrapper::Fork );
use Test::More;

plan tests => 1;

my $initial_pid = $$;

my $exit    = '';

$SIG{ CHLD } = sub { $exit = $? };

my $frang
= do
{
    my $b   = bless \( my $a = '' ), 'Object';

    __PACKAGE__->new( $b )
};

if( my $pid = fork )
{
        wait;

        ok ! $exit, "Child exited cleanly ($pid)";
}
elsif( defined $pid )
{
    # child uses deafult (stub) cleanup
    # and should exit cleanly without 
    # calling anything.

    undef $frang;

    exit 0;
}
else
{
    BAIL_OUT "Phorkafobia: $!"
}

# this is not a module

0

__END__
