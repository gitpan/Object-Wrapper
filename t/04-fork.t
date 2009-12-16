
package Testify;

use v5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";
use base qw( Object::Wrapper::Fork );

use Test::More;

plan tests => 2;

my $auto    = '';
my $exit    = '';

sub Object::frobnicate
{
    $auto   = 1;
}

$SIG{ CHLD }
= sub
{
    $exit = $?
};

my $franger
= do
{
    my $b   = bless \( my $a = '' ), 'Object';

    __PACKAGE__->new( $b )
};

if( my $pid = fork )
{
    $franger->frobnicate;

    ok $auto,   'Parent calls frobnicate';

    wait;

    ok ! $exit, "Child exited cleanly ($exit)";
}
elsif( defined $pid )
{
    # child uses deafult (stub) cleanup
    # and should exit cleanly without 
    # calling anything.

    undef $franger;

    exit 0;
}
else
{
    BAIL_OUT "Phorkafobia: $!"
}

# this is not a module

0

__END__
