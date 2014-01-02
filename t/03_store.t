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
	lives_ok {
		$t->store('foo', 'bar');
	};
	
	is($_->fetch('foo'), 'bar') for @{ $t->layers };
};

subtest 'rollback', sub {
	my $t = Plack::Session::Store::Transparent->new(
		layers => [
			t::lib::HashSession->new,
			t::lib::HashSession->new(dies_on_store => 1),
			t::lib::HashSession->new,
		]
	);
	$t->layers->[0]->store('foo', 'baz');

	throws_ok {
		$t->store('foo', 'bar');
	} qr/die for testing in store/;
	
	ok($t->fetch('foo'), 'baz');
	is($t->layers->[0]->fetch('foo'), 'baz');
	ok(! $t->layers->[1]->fetch('foo'));
	ok(! $t->layers->[2]->fetch('foo'));
};

done_testing;

