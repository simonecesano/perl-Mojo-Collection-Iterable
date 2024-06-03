package Mojo::Collection::Iterable;
use Mojo::Util qw/dumper/;
use Mojo::Base -base;

use Mojo::Collection;
use Scalar::Util qw/blessed/;
use Class::Method::Modifiers;

# ABSTRACT: turns baubles into trinkets

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
		     reduce
		     reverse
		     shuffle
		     size
		     sort
		     tail
		     tap
		     to_array
		     uniq
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

	    if ((blessed $ret) && ($ret->isa("Mojo::Collection") || ref $ret eq "ARRAY")) {
		return (ref $self)->new($ret->@*);
	    } else {
		return $ret
	    }
	}
    }
}

sub prev { $_[0]->idx > 0 ? $_[0]->collection->[$_[0]->idx - 1] : undef }
sub curr { $_[0]->collection->[$_[0]->idx] }
sub item { $_[0]->collection->[$_[0]->idx] }
sub next { $_[0]->collection->[$_[0]->idx + 1] }

sub increment { $_[0]->idx($_[0]->idx + 1) }
sub decrement { $_[0]->idx($_[0]->idx - 1) }
sub reset { $_[0]->idx(0) }

sub iterate {
    my $self = shift;
    my $ret = $self->collection->[$self->idx];
    $self->increment;
    return $ret;
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


sub from {
    my $self = shift;
    my $start = shift;
    return $self->new(@{$self}[$start..$self->idx])
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
 
L<Mojo::Collection::Iterable> adds an iterator function to Mojo::Collection and makes it subclassable via Mojo::Base as a side-effect

=head1 ATTRIBUTES

=head2 idx

=head2 collection

=head1 METHODS

=head2 prev

=head2 curr

=head2 next

=head2 increment

=head2 iterate

=head2 reset



