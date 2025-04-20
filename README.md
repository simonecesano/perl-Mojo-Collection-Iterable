# NAME

Mojo::Collection - Collection

# SYNOPSIS

     use Mojo::Collection::Iterable;
    
     # Manipulate collection
     my $collection = Mojo::Collection::Iterable->new(qw(just works));
     unshift @$collection, 'it';
     say $collection->join("\n");
    
     # Chain methods
     $collection->map(sub { ucfirst })->shuffle->each(sub ($word, $num) {
       say "$num: $word";
     });

     # iterate
     while (my $item = $c->iterate) { print $item->@*; }
    

# DESCRIPTION

# NAME

Mojo::Collection::Iterable - Collection with iterator capabilities

# SYNOPSIS

    use Mojo::Collection::Iterable;

    # Create a new collection
    my $collection = Mojo::Collection::Iterable->new(qw(it just works));

    # Use like an arrayref
    unshift @$collection, 'Indeed';
    say $collection->join("\n");

    # Chainable methods
    $collection->map(sub { ucfirst })->shuffle->each(sub ($word, $num) {
      say "$num: $word";
    });

    # Iterate manually
    $collection->reset;
    while (my $item = $collection->iterate) {
      say "Item: $item"; # returns "it"
    }

# DESCRIPTION

[Mojo::Collection::Iterable](https://metacpan.org/pod/Mojo%3A%3ACollection%3A%3AIterable) is a subclassable extension to [Mojo::Collection](https://metacpan.org/pod/Mojo%3A%3ACollection) that adds iterator-style access and extra utilites.

# ATTRIBUTES

## idx

    $int = $collection->idx;
    $collection->idx($int);

Sets/gets thecurrent position of the iterator in the collection.

## collection

    $mc = $collection->collection;

The internal [Mojo::Collection](https://metacpan.org/pod/Mojo%3A%3ACollection) object that stores the actual items.

## watches

    $watches = $collection->watches;

An arrayref of watch conditions stored as triples \`\[when => sub => name\]\`.

# METHODS

## new

    my $collection = Mojo::Collection::Iterable->new(@items);

Creates a new collection with the given list of items.

## prev

    my $item = $collection->prev;

Returns the item before the current index, or `undef` if at the beginning.

## curr

## item

    my $item = $collection->curr;
    my $item = $collection->item;

Returns the item at the current index.

## next

    my $item = $collection->next;

Returns the item after the current index, or `undef` if at the end.

## increment

    $collection->increment;

Increments the iterator index by 1.

## decrement

    $collection->decrement;

Decrements the iterator index by 1.

## reset

    $collection->reset;

Resets the index to the start (0).

## iterate

    my $item = $collection->iterate;

Returns the current item starting from the first, then increments the index.

## watch

    $collection->watch($when => $callback, $name);

Adds a watch hook (currently not invoked in the provided code, but may be used for event handling or hooks).

# OVERLOADING

This class overloads the following operators:

- `@{}` — dereference as an array.
- `""` — stringification returns the object (could be customized further).
- `${}` — scalar dereference returns the object.
- `++` — calls `increment`.
- `--` — calls `decrement`.

# SEE ALSO

[Mojo::Collection](https://metacpan.org/pod/Mojo%3A%3ACollection), [Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase), [List::Util](https://metacpan.org/pod/List%3A%3AUtil), [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)

# AUTHOR

Simone Cesano <scesano@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) Simone Cesano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
