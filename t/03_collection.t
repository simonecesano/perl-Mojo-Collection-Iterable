use Mojo::Base -strict;

use Test::More;
use Mojo::ByteStream qw(b);
use Mojo::Collection::Iterable;
use Mojo::JSON       qw(encode_json);

$\ = "\n"; $, = "\t"; 

sub c {
    return Mojo::Collection::Iterable->new(@_);
}


subtest 'Array' => sub {
  is c(1, 2, 3)->[1], 2, 'right result';
  is_deeply [@{c(3, 2, 1)}], [3, 2, 1], 'right result';
  my $collection = c(1, 2);
  push @$collection, 3, 4, 5;
  is_deeply [@$collection], [1, 2, 3, 4, 5], 'right result';
};

subtest 'Tap into method chain' => sub {
  is_deeply c(1, 2, 3)->tap(sub { $_->[1] += 2 })->to_array, [1, 4, 3], 'right result';
};

subtest 'compact' => sub {
  is_deeply c(undef, 0, 1, '', 2, 3)->compact->to_array, [0, 1, 2, 3], 'right result';
  is_deeply c(3, 2, 1)->compact->to_array,               [3, 2, 1],    'right result';
  is_deeply c()->compact->to_array,                      [],           'right result';
};

subtest 'flatten' => sub {
  is_deeply c(1, 2, [3, 4], 5, c(6, 7))->flatten->to_array, [1, 2, 3, 4, 5, 6, 7], 'right result';
  is_deeply c(undef, 1, [2, {}, [3, c(4, 5)]], undef, 6)->flatten->to_array, [undef, 1, 2, {}, 3, 4, 5, undef, 6],
    'right result';
};

subtest 'each' => sub {
  my $collection = c(3, 2, 1);
  is_deeply [$collection->each], [3, 2, 1], 'right elements';
  $collection = c([3], [2], [1]);
  my @results;
  $collection->each(sub { push @results, $_->[0] });
  is_deeply \@results, [3, 2, 1], 'right elements';
  @results = ();
  $collection->each(sub { push @results, shift->[0], shift });
  is_deeply \@results, [3, 1, 2, 2, 1, 3], 'right elements';
};

subtest 'first' => sub {
  my $collection = c(5, 4, [3, 2], 1);
  is $collection->first, 5, 'right result';
  is_deeply $collection->first(sub { ref $_ eq 'ARRAY' }), [3, 2], 'right result';
  is $collection->first(sub { shift() < 5 }),      4,     'right result';
  is $collection->first(qr/[1-4]/),                4,     'right result';
  is $collection->first(sub { ref $_ eq 'CODE' }), undef, 'no result';
  $collection = c(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9));
  is_deeply $collection->first(first => sub { $_ == 5 })->to_array, [4, 5, 6], 'right result';
  $collection = c();
  is $collection->first,                undef, 'no result';
  is $collection->first(sub {defined}), undef, 'no result';
};

subtest 'last' => sub {
  is c(5, 4, 3)->last,          3, 'right result';
  is c(5, 4, 3)->reverse->last, 5, 'right result';
  is c()->last, undef, 'no result';
};

subtest 'grep' => sub {
  my $collection = c(1, 2, 3, 4, 5, 6, 7, 8, 9);
  is_deeply $collection->grep(qr/[6-9]/)->to_array,          [6, 7, 8, 9], 'right elements';
  is_deeply $collection->grep(sub {/[6-9]/})->to_array,      [6, 7, 8, 9], 'right elements';
  is_deeply $collection->grep(sub { $_ > 5 })->to_array,     [6, 7, 8, 9], 'right elements';
  is_deeply $collection->grep(sub { $_ < 5 })->to_array,     [1, 2, 3, 4], 'right elements';
  is_deeply $collection->grep(sub { shift == 5 })->to_array, [5],          'right elements';
  is_deeply $collection->grep(sub { $_ < 1 })->to_array,     [],           'no elements';
  is_deeply $collection->grep(sub { $_ > 9 })->to_array,     [],           'no elements';
  $collection = c(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9));
  is_deeply $collection->grep(first => sub { $_ >= 5 })->flatten->to_array, [4, 5, 6, 7, 8, 9], 'right result';
};

subtest 'join' => sub {
  my $collection = c(1, 2, 3);
  is $collection->join,                  '123',       'right result';
  is $collection->join(''),              '123',       'right result';
  is $collection->join('---'),           '1---2---3', 'right result';
  is $collection->join("\n"),            "1\n2\n3",   'right result';
  is $collection->join('/')->url_escape, '1%2F2%2F3', 'right result';
};

subtest 'map' => sub {
  my $collection = c(1, 2, 3);
  is $collection->map(sub { $_ + 1 })->join(''), '234', 'right result';
  is_deeply [@$collection], [1, 2, 3], 'right elements';
  is $collection->map(sub { shift() + 2 })->join(''), '345', 'right result';
  is_deeply [@$collection], [1, 2, 3], 'right elements';
  $collection = c(c(1, 2, 3), c(4, 5, 6), c(7, 8, 9));
  is $collection->map('reverse')->map(join => "\n")->join("\n"), "3\n2\n1\n6\n5\n4\n9\n8\n7", 'right result';
  is $collection->map(join => '-')->join("\n"),                  "1-2-3\n4-5-6\n7-8-9",       'right result';
};

subtest 'reverse' => sub {
  my $collection = c(3, 2, 1);
  is_deeply $collection->reverse->to_array, [1, 2, 3], 'right order';
  $collection = c(3);
  is_deeply $collection->reverse->to_array, [3], 'right order';
  $collection = c();
  is_deeply $collection->reverse->to_array, [], 'no elements';
};

subtest 'shuffle' => sub {
  my $collection = c(0 .. 10000);
  my $random     = $collection->shuffle;
  is $collection->size, $random->size, 'same number of elements';
  isnt "@$collection",  "@$random",    'different order';
  is_deeply c()->shuffle->to_array, [], 'no elements';
};

subtest 'size' => sub {
    my $collection = c();
    is $collection->size, 0, 'right size';
    $collection = c(undef);
    is $collection->size, 1, 'right size';
    $collection = c(23);
    is $collection->size, 1, 'right size';
    $collection = c([2, 3]);
    is $collection->size, 1, 'right size';
    $collection = c(5, 4, 3, 2, 1);
    is $collection->size, 5, 'right size';
};

subtest 'TO_JSON' => sub {
  is encode_json(c(1, 2, 3)), '[1,2,3]', 'right result';
};

subtest 'head' => sub {
  my $collection = c(1, 2, 5, 4, 3);
  is_deeply $collection->head(0)->to_array,  [],              'right result';
  is_deeply $collection->head(1)->to_array,  [1],             'right result';
  is_deeply $collection->head(2)->to_array,  [1, 2],          'right result';
  is_deeply $collection->head(-1)->to_array, [1, 2, 5, 4],    'right result';
  is_deeply $collection->head(-3)->to_array, [1, 2],          'right result';
  is_deeply $collection->head(5)->to_array,  [1, 2, 5, 4, 3], 'right result';
  is_deeply $collection->head(6)->to_array,  [1, 2, 5, 4, 3], 'right result';
  is_deeply $collection->head(-5)->to_array, [],              'right result';
  is_deeply $collection->head(-6)->to_array, [],              'right result';
};

subtest 'tail' => sub {
  my $collection = c(1, 2, 5, 4, 3);
  is_deeply $collection->tail(0)->to_array,  [],              'right result';
  is_deeply $collection->tail(1)->to_array,  [3],             'right result';
  is_deeply $collection->tail(2)->to_array,  [4, 3],          'right result';
  is_deeply $collection->tail(-1)->to_array, [2, 5, 4, 3],    'right result';
  is_deeply $collection->tail(-3)->to_array, [4, 3],          'right result';
  is_deeply $collection->tail(5)->to_array,  [1, 2, 5, 4, 3], 'right result';
  is_deeply $collection->tail(6)->to_array,  [1, 2, 5, 4, 3], 'right result';
  is_deeply $collection->tail(-5)->to_array, [],              'right result';
  is_deeply $collection->tail(-6)->to_array, [],              'right result';
};


subtest 'reduce' => sub {
    my $collection = c(2, 5, 4, 1);
    print $collection->@*;
    is $collection->reduce(sub { $a + $b }),    12,    'right result';
    is $collection->reduce(sub { $a + $b }, 5), 17,    'right result';
    is c()->reduce(sub { $a + $b }),            undef, 'no result';
};


subtest 'sort' => sub {
  my $collection = c(2, 5, 4, 1);
  is_deeply $collection->sort->to_array,                          [1, 2, 4, 5], 'right order';

  is_deeply $collection->sort(sub { $b cmp $a })->to_array,       [5, 4, 2, 1], 'right order';

  is_deeply $collection->sort(sub { $_[1] cmp $_[0] })->to_array, [5, 4, 2, 1], 'right order';
  $collection = c(qw(Test perl Mojo));
  is_deeply $collection->sort(sub { uc(shift) cmp uc(shift) })->to_array, [qw(Mojo perl Test)], 'right order';
  $collection = c();
  is_deeply $collection->sort->to_array,                    [], 'no elements';
  is_deeply $collection->sort(sub { $a cmp $b })->to_array, [], 'no elements';
};

use Mojo::Util qw/dumper/;

subtest 'uniq' => sub {
    my $collection = c(1, 2, 3, 2, 3, 4, 5, 4);
    is_deeply $collection->uniq->to_array,                [1, 2, 3, 4, 5], 'right result';
    is_deeply $collection->uniq->reverse->uniq->to_array, [5, 4, 3, 2, 1], 'right result';

    $collection = c([1, 2, 3], [3, 2, 1], [3, 1, 2]);

    is_deeply $collection->uniq(sub { $_->[1] })->to_array, [[1, 2, 3], [3, 1, 2]], 'right result';

    $collection = c(c(1, 2), c(1, 2), c(2, 1));
    is_deeply $collection->uniq(join => ',')->flatten->to_array, [1, 2, 2, 1], 'right result';
    $collection = c(undef, '', 3, 2, 1, 0);
    is_deeply $collection->uniq->to_array, [undef, 3, 2, 1, 0], 'right result';
    $collection = c(undef, '', 3, 2, 1, 0);
    is_deeply $collection->uniq(sub {$_})->to_array, [undef, 3, 2, 1, 0], 'right result';
};


done_testing();
