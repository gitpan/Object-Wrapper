########################################################################
# housekeeping
########################################################################

package Object::Wrapper;

use 5.8.0;
use strict;

use Carp;

use Scalar::Util    qw( blessed refaddr reftype );

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;
our $AUTOLOAD   = '';
my %cleanupz    = ();

########################################################################
# utility subs
########################################################################

AUTOLOAD
{
    my $franger = shift;

    my $i       = rindex $AUTOLOAD, '::';
    my $name    = substr $AUTOLOAD, 2 + $i;

    my $sub     = $franger->[0]->can( $name )
    or confess "Bogus $AUTOLOAD: '$franger->[0]' cannot '$name'";

    $franger->[0]->$sub( @_ )
}

DESTROY
{
    my $franger = shift;

    my $class   = blessed $franger || $franger;

    # $cleanupz{ $class } may be a method name or coderef.

    my $cleanup = $cleanupz{ $class } || $franger->can( 'cleanup' )
    or confess "Bogus franger: no cleanup for '$franger' or '$class'";

    my $sub
    = ref $cleanup
    ? $cleanup
    : $franger->can( $cleanup )
    or confess "Bogus $class: no cleanup for '$franger' ($class)";

    'CODE' eq reftype $sub
    or confess "Bogus $class: not a coderef '$sub'";

    $cleanup->( @$franger );

    return
}

########################################################################
# public interface
########################################################################

sub new
{
    my $proto   = shift;
    my $class   = blessed $proto || $proto;

    my $object  = shift
    or croak "Bogus franger: missing object";

    bless [ $object, @_ ], $class
}

sub cleanup_handler :lvalue
{
    my $proto   = shift;
    my $class   = blessed $proto || $proto;

    @_
    and $cleanupz{ $class } = shift;

    my $tmp = \$cleanupz{ $class };

    $$tmp
}

# stub cleanup for cases where the AUTOLOAD validation
# is sufficient by itself.

sub cleanup {}

# keep require happy

1

__END__

=head1 NAME

Object::Wrapper - Sanity-check wrapper for objects.

=head1 SYNOPSIS

    pacakge My;

    # use parent works just as well if available.

    use base qw( Object::Wrapper );

    # For example, if the validation data were the current
    # process id ("$$") then AUTOLOAD could abort operations
    # called across forks (see Object::Wrapper::Fork) and
    # perform proper post-fork cleanup in DESTROY (see
    # Object::Wrapper::Fork::DBI).

    sub constructor
    {
        my $object  = WhateverWorksForYou->();

        # whatever is necessary for the autoload to validate
        # the object: pid ($$), time, use counter.
        #
        # push the virgin object and its validation data
        # into Object::Wrapper.

        my @valid   = ( ... );

        __PACKAGE__->new( $object, @valid )
    }

    # for example, if you want to check for forks:

    AUTOLOAD
    {
        my $franger = shift;

        my $pid     = $franger->[1];

        if( $pid == $$ )
        {
            my $i       = rindex $AUTOLOAD, '::';
            my $name    = substr $AUTOLOAD 2+$i;

            # call by reference allows the method to 
            # modify the object in place (e.g., trampoline).

            $franger->[0]->$name( @_ );
        }
        else
        {
            confess "Method call crosses fork: $$ ($pid)";
        }
    }

    sub cleanup
    {
        # called with the original validation data.

        my ( $head, $pid ) = @_;

        if( $pid != $$ )
        {
            # post-fork cleanup

            ...
        }
        else
        {
            # within-process 

            ...
        }
    }


    # checking for a maxium time window:

    sub new
    {
        ...

        my $window  = $seconds + time;

        __PACKAGE__->SUPER::new( $object, $window );
    }

    AUTOLOAD
    {
        my $franger = shift;

        my $cutoff  = $franger->[1];

        if( $cutoff > 0 )
        {
            ...

            $franger->[0]->$name( @_ )
        }
        else
        {
            die "Expired object ($cutoff)\n"
        }
    }

    # checking for maximum use and time:
    
    my $redispatch  = Object::Franger->can( 'new' );

    sub new
    {
        my $object  = ...;

        $redispatch->( __PACKAGE__, $object, $window, $counter )
    }

    AUTOLOAD
    {
        my $franger = shift;

        time > $franger->[1]    or die "Time expired\n";
        --$franger->[2]         or die "Overtaxed\n";

        ...
    }


    # in both of these latter cases the default stub cleanup
    # may be sufficient.

You may just want to track the object over time and see how
long it existed or how many times it was used: store a Benchmark
object and have your cleanup print the differences.
    

=head1 DESCRIPTION

Wrap objects to allow simple access and possibly
complicated validation of method calls.

The skeleton provided here handles Fork issues,
particulary those for DBI and DBD::* handles.
Adding extra layers for timeouts or maxiumum 
number of uses is also simple enougn.

The bulk of the work is done in AUTOLOAD, which
re-validates the object prior to dispatching it
by reference (i.e., this works with trampolines
and other method-modifyer modules).

DESTROY calls the wrapped object with its original
arguments, which can be checked on the way out for
appropriate cleanup (e.g., within-proc or post-fork).

=head2 Interface

=over 4

=item new

This takes a reference to the object or package being
wrapped and returns the wrapper. It would normaly be
called from the wrapped objects constructor:

    sub your_constructor
    {
        my $thingy  = $madness->$method( @argz );

        Object::Wrapper->new( $thingy, @sanity );
    }

This will accept a package name, if the things you
are trying to wrap are all class methods:

    sub construct
    {
        Object::Wrapper->new( __PACKAGE__, @sanity )
    }

=item cleanup

This is provided in the wrapped object's space.  

Its job is to clean up after the object on a 
fork. For example, DBI handles usually cannot be 
shared across forks. The "InactiveDestroy" flag 
helps one side close down the objects safely by 
disabling the side effects of destruction.

For example, handling DBI handles with forks 
can be done with:

    sub connect
    {
        ...
        my $dbh = DBI->connect( @argz );

        Object::Wrapper->new( $dbh, $$ );
    }

    AUTOLOAD
    {
        my $franger = shift;

        my ( $object, $pid ) = @$franger;

        $pid == $$
        or confess "Oops: dbh crossed fork ($pid, $$)";

        my $name = ...

        $object->$name( @_ )
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

            log_message "DB Handle: ignore ($pid)";

            $_->{ InactiveDestroy } = 1
            for
            (
                $dbh,
                @kidz
            );

            $struct
            and %$struct = ();
        }
        else
        {
            log_message "DB Handle: finalize ($pid)";

            $_->{ InactiveDestroy } = 1
            for
            (
                $dbh,
                @kidz
            );

            # purge the global cache, if there is one.

            $struct
            and %$struct = ();
        }

        # at this point the DBI object has been
        # prepared to go out of scope politely.
    }

In fact, this is what Object::Wrapper::Fork 
(AUTOLOAD) and Object::Wrapper::Fork::DBI 
(cleanup) do for you.

=item cleanup_handler

Returns the cleanup handler (assignable). Used in 
cases where the class uses different name for the 
cleanup or wants to dispatch into a different class.

Also useful for re-dispatching class-specific 
handlers in a base-class cleanup.

    # install a new handler by name or coderef 
    # as an argument or via assignment.
    #
    # $thingy can be either an object or class
    # name. in the former the handler will be
    # instlled for "blessed $thingy.

    $thingy->cleanup_handler( $coderef );
    $thingy->cleanup_handler( $name    );

    $thingy->cleanup_handler    = $name;
    $thingy->cleanup_handler    = $coderef;

    # get the current handler.

    my $handler = $object->cleanup_handler;

    goto &$handler;

=item AUTOLOAD

This is provided by classes derived from 
Object::Wrapper. This is where the 
object is re-validated.

Follows the standard rules, gets the franger as
first argument, should usually replace the 
franger with an object on the way out:

    AUTOLOAD
    {
        my ( $franger ) = @_;

        my ( $object, @stuff ) = @$franger;

        validate_the_call or croak ...;

        my $i       = rindex '::', $AUTOLOAD;
        my $name    = substr $AUTOLOAD, 2 + $i;
        my $sub     = $object->can( $name )
        or croak ...;

        local *tmp;

        *tmp    = \$object;

        splice @_, 1, 1, *tmp;

        goto &$sub
    }

=item DESTROY

Where the object's cleanup is called. The default
is to dispatch into $object->can( 'cleanup' ). This
can be altered by storing a string or coderef using
$object->cleanup_handler.

=back

=head1 NOTES

=over 4

=item Using classes.

Passing in a class as the "$object" argument
will result in class methods being redispatched
and the class being called to clean itself up
when the franger object goes out of scope. This
can be useful for limiting the scope of singleton
objects or implementing things like transactions
with a wrapped $dbh.

=item Tied Objects

This module does not support BSDM. Anyone doing 
this to their objects will have to do it somewhere
else.

=back

=head1 SEE ALSO

=over

=item Object::Wrapper::Fork

Supplies new, AUTOLOAD that validate the original pid
againsed $$.

=item Object::Wrapper::Fork::DBI

Supplies connect (takes same arguments as DBI->connect)
and cleanup that handles CachedKids appropriately
pre- or post-fork.

=item Object::Wrapper::Count

Supplies AUTOLOAD that decrements a counter, with 
a die "Object count expired\n".

=item Object::Wrapper::Window

Supplies AUTOLOAD that comapres time a cutoff,
with a die "Object time expired\n".

= Object::Wrapper::Benchmark

Supplies new that stores a Benchmark and counter
in the object, AUTOLOAD that counts the calls,
cleanup that reports the time and count.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009 Steven Lembark. This module is released
under the same terms as Perl-5.10.0 itself.
