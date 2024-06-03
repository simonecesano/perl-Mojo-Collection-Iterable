package Mojo::Collection::Iterable::Role::Statistics;
use Mojo::Base -role;

use Statistics::Descriptive::Full;

has statistics => sub { Statistics::Descriptive::Full->new() };

use Mojo::Loader qw(data_section find_modules load_class);
use Carp;
sub BEGIN {
    # no strict 'refs';
    # for my $module (find_modules 'Statistics::Descriptive') {
    # 	print $module;
    # }
}

sub AUTOLOAD {
    no strict qw/refs/;
    no warnings qw/redefine/;
    my $self = shift;
    our $AUTOLOAD;

    my $sub = $AUTOLOAD =~ s/.*:://r;
    my $class = ref $self;
    # print "class:    $class";
    # print "autoload: $AUTOLOAD";

    if (Statistics::Descriptive::Full->can($sub)) {
	*{join "::",  __PACKAGE__, "$sub"} = sub {
	    my $self = shift;
	    $self->statistics->clear();
	    $self->statistics->add_data($self->collection->@*);
	    return $self->statistics->$sub(@_);
	}
    } else {
	croak "cannot find method $sub";
    }
    $sub->($self, @_);
}

1

