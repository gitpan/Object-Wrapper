
use 5.8.0;
use strict;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use File::Basename;
use Test::More;

my $base    = basename $0, '.t';

$base       =~ s{ \d+ \W }{}x;

my $module  = join '::', split /\W+/, $base;

my @required
= qw
(
    new
    cleanup_handler
);

plan tests => 1 + @_;

# note that this will carp if DBI is not present,
# but won't fail.

use_ok $module;

ok $module->can( $_ ), "$module can '$_'"
for @_;

# keep require happy

1

__END__
