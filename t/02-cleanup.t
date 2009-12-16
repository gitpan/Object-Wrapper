
package Testify;

use 5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use base qw( Object::Wrapper );

use Object::Wrapper;
use Test::More;

plan tests => 2;

my $auto    = '';
my $expect  = rand 100;
my $found   = '';

sub Object::frobnicate
{
    $auto = 1
}

sub cleanup
{
    my ( undef, $validate ) = @_;

    $found  = $validate;
}

{
    my $b       = bless \( my $a = '' ), 'Object';

    my $franger = __PACKAGE__->new( $b, $expect );

    $franger->frobnicate;
};

ok $auto,               'Frobnicate called';
ok $found   == $expect, "Cleanup Called with '$found' ($expect)";

# this is not a module

0

__END__
