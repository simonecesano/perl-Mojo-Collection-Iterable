use Test::More;
use Mojo::Collection::Iterable;

my $c = Mojo::Collection::Iterable->new;

isa_ok($c, "Mojo::Collection::Iterable");

done_testing()
