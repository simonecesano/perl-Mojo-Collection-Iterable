package Mojo::Collection::Iterable::Role::Breaks;

use Mojo::Util qw/dumper/;
use Mojo::Base -role;

use Want;

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

    # break-after after last row: always true
    if ($when eq "after" && $self->idx >= ($self->size - 1)) {
	return 1;
    }
    # break-after on intermediate row: check
    elsif ($when eq "after" && $self->idx >= 1 && _is_break($self->curr, $self->next, @subs)) {
	return 1;
    }
    # break-before before first row: always true
    elsif ($when eq "before" && $self->idx < 1) {
	return 1;
    }
    # break-before on intermediate row: check
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
