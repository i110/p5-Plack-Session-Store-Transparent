use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Session::Store::Transparent;

use t::lib::HashSession;

subtest 'simple', sub {
	my $t = Plack::Session::Store::Transparent->new(
		layers => [
			t::lib::HashSession->new,
			t::lib::HashSession->new,
			t::lib::HashSession->new,
		]
	);

	$t->layers->[0]->store('foo', 'bar');
	is($t->fetch('foo'), 'bar');
	# filled with the data from origin
	is($t->layers->[1]->fetch('foo'), 'bar');
	is($t->layers->[2]->fetch('foo'), 'bar');
	
};

subtest 'not access to origin if caches have session', sub {
	my $t = Plack::Session::Store::Transparent->new(
		layers => [
			t::lib::HashSession->new(dies_on_fetch => 1),
			t::lib::HashSession->new,
			t::lib::HashSession->new,
		]
	);

	$t->store('foo', 'bar');
	lives_ok {
		is($t->fetch('foo'), 'bar');
	};
	
};

done_testing;

