=head1 NAME

Parse::ErrorString::Perl - Parse error messages from the perl interpreter

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Parse::ErrorString::Perl qw(parse_string);

    my @errors = parse_string($string_containing_stderr_output);
    
    foreach my $error(@errors) {
	print 'Captured error message "' .
	    $error->message .
	    '" in file ' . $error->file .
	    ' on line ' . $error->line . "\n";
    }
    

=head1 EXPORT

Exports a single function: C<parse_string>.

=head1 FUNCTIONS

=head2 parse_string($string)

Receives an error string generated from the perl interpreter and attempts to parse it into a list of C<Parse::ErrorString::Perl::ErrorItem> objects providing information for each error. 

=head1 Parse::ErrorString::Perl::ErrorItem

Each object contains the following accessors (only C<message>, C<file>, and C<line> are guaranteed to be present for every error):

=over 9

=item type

A single letter idnetifying the type of the error. The possbile options are C<W>, C<D>, C<S>, C<F>, C<P>, C<X>, and C<A>.

=item type_description

A description of the error type. The possible options are:

    W => warning 
    D => deprecation
    S => severe warning
    F => fatal error
    P => internal error
    X => very fatal error
    A => alien error message

=item message

The error message.

=item file

The name of the file in which the error occurred, with the path possibly trunicated. If the error occurred in a script, the parser will attempt to return only the filename; if the error occurred in a module, the parser will attempt to return the path to the module relative to the directory in @INC in which it resides.

=item file_path

Absolute path to the file in which the error occurred.

=item line

Line in which the error occurred.

=item near

Text near which the error occurred.

=item diagnostics

Detailed explanation of the error (from L<perldiag>). Returned as pod, so you may need to use a pod parser to render into the format you need.

=item stack

Callstack for the error (not implemented yet).

=back

=head1 AUTHOR

Petar Shangov, C<< <pshangov at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-errorstring-perl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-ErrorString-Perl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::ErrorString::Perl


=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-ErrorString-Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-ErrorString-Perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-ErrorString-Perl>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-ErrorString-Perl/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Petar Shangov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

use warnings;
use strict;

package Parse::ErrorString::Perl::StackItem;

sub new {
    my ($class, $self) = @_;
    bless $self, ref $class || $class;
    return $self;
}

package Parse::ErrorString::Perl::ErrorItem;

use Class::XSAccessor
    getters => {
	type => 'type',
	type_description => 'type_description',
	message => 'message',
	file => 'data',
	file_path => 'file_path',
	line => 'line',
	near => 'near',
	diagnostics => 'diagnostics',
	stack => 'stack',
    };

sub new {
    my ($class, $self) = @_;
    bless $self, ref $class || $class;
    return $self;
}

package Parse::ErrorString::Perl;

our $VERSION = '0.01';

use Carp;
use Pod::Find qw(pod_where contains_pod);
use base 'Exporter';

our @EXPORT_OK = qw(parse_string);

sub parse_string {
    my $string = shift;
    my @hash_items = _parse_to_hash($string);
    my @object_items;
    
    foreach my $item (@hash_items) {
	my $error_object = Parse::ErrorString::Perl::ErrorItem->new($item);
	push @object_items, $error_object;
    }
    
    return @object_items;
}

sub _get_diagnostics {
    my $pod_filename = pod_where({-inc => 1}, 'perldiag');
    if (!$pod_filename) {
	carp "Could not locate perldiag, diagnostic info will no be added";
	return;
    }
    
    # TODO
}

sub _parse_to_hash {
    my $string = shift;
    
    if (!$string) {
	carp "parse_string called without an argument";
	return;
    }
    
    my @error_list;
    
    my @lines = split(/\n/, $string);
    
    # used to check if we are in a multi-line 'near' message
    my $in_near;
    
    foreach my $line (@lines) {
	
	# carriage returns may remain in multi-line 'near' messages and cause problems
	$line =~ s/\r/ /g;
	
	if (!$in_near) {
	    if ($line =~ /^(.*)\sat\s(.*)\sline\s(\d+)(\.|,\snear\s\"(.*)(\")*)$/) {
		my %err_item = (
		    message => $1,
		    file    => $2,
		    line  => $3,
		);
		my $near     = $5;
		my $near_end = $6;
		
	
		if ($near and !$near_end) {
		    $in_near = $near; 
		} elsif ($near and $near_end) {
		    $err_item{near} = $near;
		}
		
		push @error_list, \%err_item;
	    } 
	
	} else {
	    if ($line =~ /^(.*)\"$/) {
		$in_near .= $1;
		$error_list[-1]->{near} = $in_near;
		$in_near = "";
	    } else {
		$in_near .= $line;
	    }
	}
    }
    return @error_list;
}

1;
