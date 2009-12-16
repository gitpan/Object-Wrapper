
package Testify;

use v5.10.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use base qw( Object::Wrapper );

use Test::More;

use Scalar::Util    qw( blessed refaddr reftype );

plan tests => 3;

my $initial_pid = $$;

my $other_object    = bless {}, 'Whatever';

sub cleanup
{
    my ( $object ) = @_;

    my $type    = reftype $other_object;
    my $addr    = refaddr $other_object;
    my $class   = blessed $other_object;

    ok reftype $object eq $type,  "$object is now $type";
    ok refaddr $object eq $addr,  "$object is now $addr";
    ok blessed $object eq $class, "$object is now $class";
}

sub Object::frobnicate
{
    $_[0]   = $other_object;
}

my $b       = bless \( my $a = '' ), 'Object';

my $franger = __PACKAGE__->new( $b );

$franger->frobnicate;

# this is not a module

0

__END__
