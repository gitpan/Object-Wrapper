
package Testify;

use 5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use base qw( Object::Wrapper::Fork );

use Object::Wrapper;
use Test::More;

plan tests => 3;

sub Object::frobnicate
{
    1
}

my $expect  = $$ + 1;
my $found   = '';

sub cleanup
{
    ( undef, $found ) = @_;
}

my $auto
= eval
{
    my $b       = bless \( my $a = '' ), 'Object';

    my $franger = __PACKAGE__->new( $b );

    # offset the pid, which causes the 
    # dispatch to frobnicate to fail.

    ++$franger->[1];

    $franger->frobnicate
};

my $error   = $@;

my $sanity  = index $error, q{Bogus Testify::frobnicate: Object=SCALAR};

print "\n$@\n";

ok ! $auto,             'frobnicate call failed';
ok ! $sanity,           'frobnicate caught in AUTOLOAD';
ok $found   == $expect, "Cleanup Called with '$found' ($expect)";

# this is not a module

0

__END__
