use Mojo::Collection::Iterable;
use Mojo::Util qw/dumper/;
use Mojo::Loader qw/data_section/;
use Mojo::Template;

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my $c = Mojo::Collection::Iterable->new([a, 1], [b, 1], [c, 2], [d, 2], [e, 2], [f, 3]);

print dumper $c->[0];

for ($c->collection->@*) { print $_->@* }

while (my $item = $c->iterate) { print $item->@*; }

$c->each(sub { print $c->idx, $_->@* })
