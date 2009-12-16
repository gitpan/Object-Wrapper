
use 5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use File::Basename;
use Test::More;

my $base    = basename $0, '.t';

$base       =~ s{ \d+ \W }{}x;

my $module  = join '::', split /\W+/, $base;

plan tests => 1 + @_;

use_ok $module;

ok $module->can( $_ ), "$module can '$_'"
for @_;

# keep require happy

1

__END__
