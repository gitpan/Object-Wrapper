########################################################################
# housekeeping
########################################################################

package Object::Wrapper::Fork::DBI;

use 5.8.0;
use strict;
use parent  qw( Object::Wrapper::Fork );

use Carp;

eval { use DBI; 1 }
or carp __PACKAGE__ . ' failed using DBI';

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = 0.03;

########################################################################
# utility subs
########################################################################

########################################################################
# public interface
########################################################################

sub connect
{
    # discard the object/class: this is a factory.

    shift;

    my $dbh     = DBI->connect( @_ )
    or croak 'Fail connect: ' . $DBI::errstr;

    Object::Wrapper::Fork::dbh->new( $dbh )
}

sub connect_cached
{
    shift;

    my $dbh     = DBI->connect_cached( @_ )
    or croak 'Fail connect_cached: ' . $DBI::errstr;

    Object::Wrapper::Fork::dbh->new( $dbh )
}

########################################################################
# handlers for database and statement handles
#
# both inherit AUTOLOAD from Fork (i.e., they check the pid).
########################################################################

package Object::Wrapper::Fork::dbh;

use 5.8.0;
use strict;
use parent  qw( Object::Wrapper::Fork );

use Carp    qw( croak confess );

sub prepare
{
    my $franger = shift;

    my ( $dbh, $pid ) = @$franger;

    $pid == $$
    or confess "Bogus prepare: @{ $franger } crosses fork.";

    my $sth = $dbh->prepare( @_ )
    or croak 'Failed prepare: ' . $dbh->errstr;

    Object::Wrapper::Fork::sth->new( $sth )
}

sub prepare_cached
{
    my $franger = shift;

    my ( $dbh, $pid ) = @$franger;

    $pid == $$
    or confess "Bogus prepare_cached: @{ $franger } crosses fork.";

    my $sth = $dbh->prepare_cached( @_ )
    or croak 'Failed prepare_cached: ' . $dbh->errstr;

    Object::Wrapper::Fork::sth->new( $sth )
}

sub cleanup
{
    my ( $dbh, $pid ) = @_;

    my $struct
    = do
    {
        my $drh     = $dbh->{ Driver };

        $drh
        ? $drh->{ CachedKids }
        : ''
    };

    my @kidz
    = $struct
    ? values %$struct
    : ()
    ;

    if( $$ != $pid )
    {
        # handle crossed a fork: turn off side
        # effects of destruction.

        $_->{ InactiveDestroy } = 1
        for
        (
            $dbh,
            @kidz
        );
    }
    else
    {
        $_->finish for @kidz;

        $dbh->disconnect;
    }

    # at this point the DBI object has been
    # prepared to go out of scope politely.

    return
}

########################################################################
# cleanup handler for statement handles

package Object::Wrapper::Fork::sth;

use 5.8.0;
use strict;
use parent qw( Object::Wrapper::Fork );

sub cleanup
{
    my ( $sth, $pid ) = @_;

    if( $$ ~~ $pid )
    {
        # same process: finalize the handle and disconnect.
        # caller deals with clones.

        $sth->{ Active } 
        and $sth->finish;
    }
    else
    {
        $sth->{ InactiveDestroy } = 1;
    }

    # at this point the DBI object has been
    # prepared to go out of scope politely.

    return
}


# keep require happy

1

__END__

=head1 NAME

Object::Wrapper::Fork::DBI -- Practice safe procs for forked
DBI handles.

=head1 SYNOPSIS

    package My;

    use parent qw( Object::Wrapper::Fork::DBI );

    # this supplies the constructor and cleanup
    # for Object::Wrapper used with database or
    # statement handles ("$dbh" or "$sth").
    # 
    # construcion looks just like DBI except for
    # the funny name:

    my $dbh = My->connect( $dsn, @blah );

    # from here on in method calls just look like an
    # ordinary DBI unless they cross fork boundries.
    # in that case the forked proc will croak with
    # a mismatched-pid error.


    if( my $pid = fork )
    {
        # feel free: this is in the same process.
        # this prepare (and prepare_cached) return
        # a wrapped statement handle.

        my $sth = $dbh->prepare( $sql );
    }
    elsif( defined $pid )
    {
        # any method calls to $dbh in here will 
        # croak. undef-ing $dbh or just letting
        # it fall out of scope normally is fine.
        #
        # $dbh->prepare( $sql ) <-- this will die!

        undef $dbh;             # this is safe

        ...

        exit 0                  # or just let it go out of scope
    }
    else
    {
        die "Phorkafobia: $!"
    }

=head1 DESCRIPTION

=head2 What you see is all you get.

This just supplies minimal methods for
the standard DBI constructors: connect,
connect_cached, prepare, prepare_cached.
These return wrapped objects which
inherit from Object::Wrapper::Fork.

=head2 Database Handles ("$dbh")

The "connect" method is a constructor that 
passes C<DBI->connect( @_ )> to 
Object::Wrapper::Fork::new. 

This is also where connect and connect_cached
come from (anything else goes through the
AUTOLOAD in O::F::Fork for sanity checks and
gets passed along).

The supplied cleanup (most of this code) 
compares the current process id ("$$") with the 
pid that created the database handle.  If the 
pid's match then DESTROY will finish any of
C<{ Driver }{ CachedKids }> that are active and 
disconnect the database handle; if not then they 
all get C<{ InactiveDestroy }> set to true, the 
CachedKids structure is emptied and the $dbh 
undef-ed.

=head2 Statement Handles ("$sth")

The supplied cleanups check the pid and either 
finish the object if it is active or set
InactiveDestroy.

=head2 BSDM is not supported.

Due to perly inheritence, and performance issues, the 
tied DBI interface is not supported: only method calls
are dispatched properly.

Fortunately, DBI is well thought out enought that you
probably never really need to use the tied interface
in your code.

=head1 SEE ALSO

=over 4

=item Object::Wrapper

Top-level constructor and DESTROY that dispatches
the cleanup for the wrapper contents.

=item Object::Wrapper::Fork

Constructor supplies pid to Object::Wrapper::new,
AUTOLOAD checks the original pid againsed $$.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009 Steven Lembark. This module is released
under the same terms as Perl-5.10.0 itself.
