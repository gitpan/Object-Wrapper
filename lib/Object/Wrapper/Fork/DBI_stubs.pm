########################################################################
# housekeeping
########################################################################

package Object::Wrapper::Fork::DBI_stubs;

use 5.8.0;
use strict;
use parent  qw( Object::Wrapper::Fork );

use Carp;

use Symbol  qw( qualify qualify_to_ref );

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = 0.01;

########################################################################
# utility subs
########################################################################

sub import
{
    my $caller  = caller;

    for( qw( connect connect_cached ) )
    {
        # stub out the normal constructors.

        my $name    = qualify $_, $caller;
        my $ref     = qualify_to_ref $name;

        undef &{ *$ref };

        *$ref = sub { croak "Bogus $name: DBI not avaialble" };
    }
}
__END__

=head1 NAME

Object::Wrapper::Fork::DBI_stubs -- croak on call if
DBI is not avaiable and the caller is used.

=head1 SYNOPSIS

    # DBI is not installed.

    package My;

    use parent qw( Object::Wrapper::Fork::DBI );

    # so far no harm, no foul: code that wants to 
    # test the Fork::DBI module can do so.
    #
    # calling connect, however, croaks since DBI
    # is not available.

    my $dbh = My->connect( $dsn, @blah );

=head1 DESCRIPTION

This avoids requiring a hard-wired dependency on 
DBI for users who do not need O::W::Fork::DBI.

Fork::DBI eval's its "use DBI" and carps if there
is no DBI installed. Calls to "connect" croak in
the Fork::DBI class.

This saves testing for DBI being installed on 
every single call to any of the Fork::DBI methods.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009 Steven Lembark. This module is released
under the same terms as Perl-5.10.0 itself.

