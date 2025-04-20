package Mojo::Collection::Iterable;
use Mojo::Base -base;

use Mojo::Collection;
use Scalar::Util qw/blessed/;
use Class::Method::Modifiers;

# ABSTRACT: turns baubles into trinkets
use List::Util;

use overload
    '@{}' => sub { shift->collection },
    '""' => sub { return shift },
    '${}' => sub { return shift },
    '++' => sub { shift->increment },
    '--' => sub { shift->decrement },
    "fallback" => 1;

has "idx" => 0;

has "collection" => sub { Mojo::Collection->new() };

has "watches" => sub { [] }; 

around 'new' => sub {
    my $orig = shift;
    my $self = shift;
    my $ret = $orig->($self, { collection => Mojo::Collection->new( @_) });
    return $ret;

};

sub BEGIN {
    my @subs = qw/
		     TO_JSON
		     compact
		     first
		     grep
		     head
		     join
		     last
		     map
		     reverse
		     shuffle
		     size
		     tail
		     tap
		 /;
    no strict 'refs';

    foreach my $name (@subs) {
	local $\ = "\n";
	# next unless defined &$name;
	# my $new_name = '' . $name;
	# print STDERR join "::",  __PACKAGE__, "$name";

	no strict "refs"; 

	*{join "::",  __PACKAGE__, "$name"} = sub {
	    my $self = shift;

	    my $ret = $self->collection->$name(@_);

	    print ref $self, $name, $ret, @_ if $name eq "reduce";

	    if ((blessed $ret) && ($ret->isa("Mojo::Collection") || ref $ret eq "ARRAY")) {
		return (ref $self)->new($ret->@*);
	    } else {
		return $ret
	    }
	}
    }
}

# --------------------------------------------
# these had to be defined explicitly here
# otherwise the whole thing would break
# I don't remember why but it did
# probably deep recursion
# --------------------------------------------

sub reduce {
    my $self = shift;
    @_ = (@_, $self->collection->@*);
    goto &List::Util::reduce;
}

sub sort {
    my ($self, $cb) = @_;
    return $self->new(sort @$self) unless $cb;

    my $caller = caller;
    no strict 'refs';

    my @sorted = sort {
	local (*{"${caller}::a"}, *{"${caller}::b"}) = (\$a, \$b);
	$a->$cb($b);
    } @$self;
    return $self->new(@sorted);
}

sub uniq {
    my ($self, $cb) = (shift, shift);
    my %seen;
    return $self->new(grep { !$seen{$_->$cb(@_) // ''}++ } $self->collection->@*) if $cb;
    return $self->new(grep { !$seen{$_ // ''}++ } $self->collection->@*);
}

sub to_array {
    my $self = shift;
    return $self->collection->to_array
}


# --------------------------------------------


sub prev { $_[0]->idx > 0 ? $_[0]->collection->[$_[0]->idx - 1] : undef }
sub curr { $_[0]->collection->[$_[0]->idx] }
sub current { $_[0]->collection->[$_[0]->idx] }
sub item { $_[0]->collection->[$_[0]->idx] }
sub next { $_[0]->idx < (-1 + scalar $_[0]->@*) ?  $_[0]->collection->[$_[0]->idx + 1] : undef }

sub reset { $_[0]->idx(0) }

sub increment { $_[0]->idx($_[0]->idx + 1) if $_[0]->idx < -1 + scalar $_[0]->@*; return $_[0] }
sub decrement { $_[0]->idx($_[0]->idx - 1) if $_[0]->idx > 0; return $_[0] }

{
    my $i = 0;
    sub iterate {
	my $self = shift;
	my $ret = $self->collection->[$i];
	if ($i < scalar $self->@*) { $self->idx($i) };
	$i++;
	return $ret
    }
}

sub _ref { ref $_[0] eq 'ARRAY' || blessed $_[0] && $_[0]->isa(__PACKAGE__) }
sub _flatten { map { _ref($_) ? _flatten(@$_) : $_ } @_ }

sub flatten { $_[0]->new(_flatten(@{$_[0]})) }
sub with_roles { shift->Mojo::Base::with_roles(@_) }

sub each {
    my ($self, $cb) = @_;
    return $self->collection->@* unless $cb;

    my $i = 1;
    $self->reset;
    for ($self->collection->@*) {
	$_->$cb($i++);
	$self->increment;
    }
    return $self;
}

sub watch {
    my $self = shift;
    my $when = shift;
    my $sub  = shift;
    my $name = shift;

    push $self->{watches}->@*, [ $when => $sub => $name ];
}

1;

=encoding utf8
 
=head1 NAME
 
Mojo::Collection - Collection
 
=head1 SYNOPSIS
 
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
 


=head1 DESCRIPTION
 
=encoding utf8

=head1 NAME

Mojo::Collection::Iterable - Collection with iterator capabilities

=head1 SYNOPSIS

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

=head1 DESCRIPTION

L<Mojo::Collection::Iterable> is a subclassable extension to L<Mojo::Collection> that adds iterator-style access and extra utilites.

=head1 ATTRIBUTES

=head2 idx

  $int = $collection->idx;
  $collection->idx($int);

Sets/gets thecurrent position of the iterator in the collection.

=head2 collection

  $mc = $collection->collection;

The internal L<Mojo::Collection> object that stores the actual items.

=head2 watches

  $watches = $collection->watches;

An arrayref of watch conditions stored as triples `[when => sub => name]`.

=head1 METHODS

=head2 new

  my $collection = Mojo::Collection::Iterable->new(@items);

Creates a new collection with the given list of items.

=head2 prev

  my $item = $collection->prev;

Returns the item before the current index, or C<undef> if at the beginning.

=head2 curr

=head2 item

  my $item = $collection->curr;
  my $item = $collection->item;

Returns the item at the current index.

=head2 next

  my $item = $collection->next;

Returns the item after the current index, or C<undef> if at the end.

=head2 increment

  $collection->increment;

Increments the iterator index by 1.

=head2 decrement

  $collection->decrement;

Decrements the iterator index by 1.

=head2 reset

  $collection->reset;

Resets the index to the start (0).

=head2 iterate

  my $item = $collection->iterate;

Returns the current item starting from the first, then increments the index.

=head2 watch

  $collection->watch($when => $callback, $name);

Adds a watch hook (currently not invoked in the provided code, but may be used for event handling or hooks).

=head1 OVERLOADING

This class overloads the following operators:

=over 4

=item *

C<@{}> — dereference as an array.

=item *

C<""> — stringification returns the object (could be customized further).

=item *

C<${}> — scalar dereference returns the object.

=item *

C<++> — calls C<increment>.

=item *

C<--> — calls C<decrement>.

=back

=head1 SEE ALSO

L<Mojo::Collection>, L<Mojo::Base>, L<List::Util>, L<Scalar::Util>

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Simone Cesano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
