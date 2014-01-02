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

	$t->store('foo', 'bar');
	is($t->fetch('foo'), 'bar');

	$t->remove('foo');
	ok(! $t->fetch('foo'));
	ok(! $t->fetch('foo')) for @{ $t->layers };
	
};

subtest 'keep consistency', sub {
	my $t = Plack::Session::Store::Transparent->new(
		layers => [
			t::lib::HashSession->new,
			t::lib::HashSession->new(dies_on_remove => 1),
			t::lib::HashSession->new,
		]
	);
	$t->store('foo', 'bar');
	is($t->fetch('foo'), 'bar');

	throws_ok {
		$t->remove('foo');
	} qr/die for testing in remove/;

	is($t->layers->[0]->fetch('foo'), 'bar');
	is($t->layers->[1]->fetch('foo'), 'bar');
	ok(! $t->layers->[2]->fetch('foo'));
	is($t->fetch('foo'), 'bar');
};

done_testing;

