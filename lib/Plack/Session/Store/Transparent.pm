package Plack::Session::Store::Transparent;
use 5.008005;
use strict;
use warnings;
use Carp;

our $VERSION = "0.01";

use parent 'Plack::Session::Store';

use Plack::Util::Accessor qw(
	layers
);

sub new {
	my ($class, %args) = @_;

	unless ($args{layers}) {
		croak "missing mandatory parameter 'layers'";
	}

	return bless { %args }, $class;
}

sub fetch {
	my ($self, $session_id) = @_;

	my @uppers;
	for my $layer (reverse @{ $self->layers }) {
		if (my $session = $layer->fetch($session_id)) {
			# ignore exceptions for availability
			eval {
				$_->store($session_id, $session) for @uppers;
			};
			return $session;
		}
		unshift(@uppers, $layer);
	}

	return;
}

sub store {
	my ($self, $session_id, $session) = @_;

	my @uppers;
	for my $layer (reverse @{ $self->layers }) {
		eval {
			$layer->store($session_id, $session);
		};
		if (my $e = $@) {
			$_->remove($session_id) for @uppers;
			croak $e;
		}

		push(@uppers, $layer);
	}
}

sub remove {
	my ($self, $session_id) = @_;

	for my $layer (reverse @{ $self->layers }) {
		$layer->remove($session_id);
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Session::Store::Transparent - Session store container which provides transparent access

=head1 SYNOPSIS

	use Plack::Builder;
	use Plack::Middleware::Session;
	use Plack::Session::Store::Transparent;
	use Plack::Session::Store::DBI;
	use Plack::Session::Store::Cache;
	use CHI;

	my $app = sub {
		return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
	};
	
	builder {
		enable 'Session',
			store => Plack::Session::Store::Transparent->new(
				layers => [
					# origin
					Plack::Session::Store::DBI->new(
						get_dbh => sub { DBI->connect(@connect_args) }
					),
					# cache
					Plack::Session::Store::Cache->new(
						cache => CHI->new(driver => 'FastMmap')
					)
				]
			);
		$app;
	};
	
	
	# with custom serializer/deserializer
	
=head1 DESCRIPTION

Plack::Session::Store::Transparent is ...

This will manipulate multiple session stores transparently.
This is a subclass of L<Plack::Session::Store> and implements its full interface.

=head1 METHODS

=over 4

=item B<new ( %args )>

The constructor expects the I<layers> argument to be an arrayref,
which contains L<Plack::Session::Store> instances, otherwise it will throw an exception.
The layers arguments should be sorted such that the origin is the first, and cache layers follow it.

=item B<fetch ( %session_id )>

Fetches session data from caches to origin, and stores the result in outside layers.

=item B<store ( %session_id, $session )>

Stores session data in all layers (from caches to origin). If one of the layer throw an exception, this method will try to keep consistency between layers, i.e. remove this session from layers which has already been stored.

=item B<remove ( %session_id )>

Removes session data from all layers (from caches to origin).

=item B<layers>

A simple accessor for the layers.

=back

=head1 LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ichito Nagata E<lt>i.nagata110@gmail.comE<gt>

=cut

