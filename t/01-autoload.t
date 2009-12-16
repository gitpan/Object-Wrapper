
package Testify;

use 5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use base qw( Object::Wrapper );
use Test::More;

plan tests => 2;

my $auto    = '';

sub Object::frobnicate
{
    $auto   = 1;
}

my $franger
= do
{
    my $b   = bless \( my $a = '' ), 'Object';

    __PACKAGE__->new( $b )
};

ok ! $franger->can( 'frobnicate' ), "$franger cannot 'frobnicate'";

# get there via autoload.

$franger->frobnicate;

ok $auto,                   'autoload used';

# this is not a module

0

__END__
