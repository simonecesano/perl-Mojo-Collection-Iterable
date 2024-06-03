package Mojo::Collection::Iterable::Role::Breaks;

use Mojo::Util qw/dumper/;
use Mojo::Base -role;

# use Mojo::Collection;
# use Class::Method::Modifiers;
# use Statistics::Descriptive;
use Want;

# use Data::Dumper;
# use List::Util;

# sub sum { return List::Util::sum (shift()->collection->@*) }

# sub deparse { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Deparse(1)->Dump }

has "breaks" => "0";
has "breakpoints" => sub { [] };

sub _is_break {
    my ($A, $B, @subs) = @_;
    for (@subs) { return 1 if !$A || !$B || ($_->($A) ne $_->($B)) }
    return 0;
}

sub check_break {
    my $self = shift;
    my ($when, $id, @subs) = @_;
    @subs = grep { ref $_ eq "CODE" } @subs;

    # final after
    if ($when eq "after" && $self->idx >= ($self->size - 1)) {
	return 1;
    }

    # intermediate after
    elsif ($when eq "after" && $self->idx >= 1 && _is_break($self->curr, $self->next, @subs)) {
	return 1;
    }
    # first before
    elsif ($when eq "before" && $self->idx < 1) {
	return 1;
    }
    # intermediate before
    elsif ($when eq "before" && _is_break($self->curr, $self->prev, @subs)) {
	return 1;
    }
    return 0
}

sub create_break {
    my ($self, $when, @subs) = @_;
    my $b = $self->breaks + 1;
    $self->breaks($b);
    my $sub = sub { $self->check_break($when, $b, @subs) };
    return $sub
}

sub break {
    my $self = shift;
    return want("BOOL") ?
	$self->check_break(@_)
	:
	$self->create_break(@_)
}


=head2 break

    my $where = "before";
    my $break_before_subref = $coll->break($where => sub { shift()->[1] } => "total");

    # later...

    $coll->each(sub {
		    if ($break_before_subref->()) {
			...
		    }
		})


Creates a subref that checks if the callback(s) return the same results on the current item and the one before or the one after.
This can be used to create headers and footers - typically in a report.

=cut

1;
