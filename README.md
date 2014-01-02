# NAME

Plack::Session::Store::Transparent - Session store container which provides transparent access

# SYNOPSIS

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
	

# DESCRIPTION

This will manipulate multiple session stores transparently.
This is a subclass of [Plack::Session::Store](https://metacpan.org/pod/Plack::Session::Store) and implements its full interface.

# METHODS

- __new ( %args )__

    The constructor expects the _layers_ argument to be an arrayref,
    which contains [Plack::Session::Store](https://metacpan.org/pod/Plack::Session::Store) instances, otherwise it will throw an exception.
    The layers arguments should be sorted such that the origin is the first, and cache layers follow it.

- __fetch ( %session\_id )__

    Fetches session data from caches to origin, and stores the result in outside layers.

- __store ( %session\_id, $session )__

    Stores session data in all layers (from caches to origin). If one of the layer throw an exception, this method will try to keep consistency between layers, i.e. remove this session from layers which has already been stored.

- __remove ( %session\_id )__

    Removes session data from all layers (from caches to origin).

- __layers__

    A simple accessor for the layers.

# LICENSE

Copyright (C) Ichito Nagata.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Ichito Nagata <i.nagata110@gmail.com>
