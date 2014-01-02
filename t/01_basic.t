use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Session::State;
use Plack::Session::Store::Transparent;

use t::lib::TestSessionHash;
use t::lib::HashSession;

t::lib::TestSessionHash::run_all_tests(
	store  => Plack::Session::Store::Transparent->new(
		layers => [
			t::lib::HashSession->new,
			t::lib::HashSession->new,
			t::lib::HashSession->new,
		]
	),
	state  => Plack::Session::State->new,
	env_cb => sub {
		open my $in, '<', \do { my $d };
		my $env = {
			'psgi.version'    => [ 1, 0 ],
			'psgi.input'      => $in,
			'psgi.errors'     => *STDERR,
			'psgi.url_scheme' => 'http',
			SERVER_PORT       => 80,
			REQUEST_METHOD    => 'GET',
			QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
		};
	},
);

done_testing;
