########################################################################
# housekeeping
########################################################################

package Object::Wrapper::Fork;

use 5.8.0;
use strict;
use parent qw( Object::Wrapper );

use Carp            qw( croak confess );
use Scalar::Util    qw( blessed );

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

our $AUTOLOAD   = '';

########################################################################
# utility subs
########################################################################

AUTOLOAD
{
    my $franger = shift;
    my ( $obj, $pid ) = @$franger;

    $pid == $$ 
    or confess "Bogus $AUTOLOAD: @{ $franger } crosses fork.";

    my $i       = rindex $AUTOLOAD, '::';
    my $name    = substr $AUTOLOAD, 2 + $i;

    my $sub     = $obj->can( $name )
    or confess "Bogus $AUTOLOAD: '$obj' cannot '$name'";

    $obj->$sub( @_ )
}

########################################################################
# public interface
########################################################################

sub new
{
    splice @_, 2, 0, $$;

    goto &Object::Wrapper::new
}

# keep require happy

1

__END__

=head1 NAME

Object::Wrapper::Fork -- Practice safe forks: use a hat.

=head1 SYNOPSIS

    pacakge My;

    # parent is lighter weight than base if it
    # is available.

    use parent qw( Object::Wrapper::Fork );

    sub cleanup
    {
        # validate 

        my ( $object, $pid ) = @_;

        if( $pid == $$ )
        {
            # clean up within same process
        }
        else
        {
            # clean up post-fork.
        }
    }

    sub new
    {
        # build the object Your Way. 
        # Object::Wrapper::Fork supplies the pid 
        # ($$) when wrapping and AUTOLOAD to 
        # validate it againsed the current pid.

        my $object  = UnforkSafe->new( @blah );

        __PACKAGE__->SUPER::new( $object )
    }

=head1 DESCRIPTION

Use Safe Forks: Wear a hat.

Any number of modules cannot gracefully handle re-use
across forks. This module provides a simple wrapper 
that re-validates the pid on calls and calls a cleanup
handler with the original PID when destroyed.

The bulk of the work is done in AUTOLOAD, which
re-validates the pid and passes the original object
by reference for each call made (i.e., modifications
to the object via $_[0] are propagated).

DESTROY calls the wrapped object with its original
pid, which can be compared to $$ for appropriate 
behavior. Passing the PID pback can simplify logging
messages or help packages that track PID's.

=head2 Interface

=over 4

=item new

This takes a reference to the object or package being
wrapped and returns the wrapper. It would normaly be
called from the wrapped objects constructor:

    sub Your::Constructor
    {
        my $proto   = shift;

        my $thingy  = $madness->$method( @argz );

        $proto->SUPER::new( $thingy )
    }

=head1 NOTES

=over 4

=item Tied Objects

This will not handle tied objects gracefully. If you're
into BSDM then you're out of luck here. Sorry.

=back

=head1 SEE ALSO

=over 4

=item Object::Wrapper

Generic constructor takes list of arguments added to the
object for validation by its AUTOLOAD and cleanup methods.

=item Object::Wrapper::Fork::DBI

Fork wrapper for DBI database handles. Supplies 
a "connect" method and cleanup handler for 
dealing with CackedKids and InactiveDestroy vs. 
finish/disconnect.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009 Steven Lembark. This module is released
under the same terms as Perl-5.10.0 itself.
