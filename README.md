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

[Mojo::Collection::Iterable](https://metacpan.org/pod/Mojo%3A%3ACollection%3A%3AIterable) adds an iterator function to Mojo::Collection and makes it subclassable via Mojo::Base as a side-effect

# ATTRIBUTES

## idx

## collection

# METHODS

## prev

## curr

## next

## increment

## iterate

## reset
