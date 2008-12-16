=head1 NAME

Parse::ErrorString::Perl - Parse error messages from the perl interpreter

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Parse::ErrorString::Perl;
	
	my $parser = Parse::ErrorString::Perl->new;
	# or: my $parser = Parse::ErrorString::Perl->new(lang => 'FR') to get localized explanations
    my @errors = $parser->parse_string($string_containing_stderr_output);
    
    foreach my $error(@errors) {
	print 'Captured error message "' .
	    $error->message .
	    '" in file ' . $error->file .
	    ' on line ' . $error->line . "\n";
    }
    

=head1 METHODS

=head2 new(lang => $lang)

Constructor. Receives an optional C<lang> parameter, specifying that error explanations need to be delivered in a language different from the default (i.e. English). Will try to load C<POD2::$lang::perldiag>.

=head2 parse_string($string)

Receives an error string generated from the perl interpreter and attempts to parse it into a list of C<Parse::ErrorString::Perl::ErrorItem> objects providing information for each error. 

=head1 Parse::ErrorString::Perl::ErrorItem

Each object contains the following accessors (only C<message>, C<file>, and C<line> are guaranteed to be present for every error):

=over 9

=item type

A single letter idnetifying the type of the error (not implemented yet). The possbile options are C<W>, C<D>, C<S>, C<F>, C<P>, C<X>, and C<A>.

=item type_description

A description of the error type (not implemented yet). The possible options are:

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

The path to the file in which the error occurred, possibly trunicated. If the error occurred in a script, the parser will attempt to return only the filename; if the error occurred in a module, the parser will attempt to return the path to the module relative to the directory in @INC in which it resides (not implemented yet).

=item file_abspath

Absolute path to the file in which the error occurred.

=item file_msgpath

The file path as displayed in which the error message.

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
	file => 'file',
	file_abspath => 'file_abspath',
	file_msgpath => 'file_msgpath',
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

our $VERSION = '0.04';

use Carp;
use Pod::Find;
use Pod::POM;
use File::Spec;

sub new {
    my $class = shift;
	my %options = @_;
    my $self = bless {}, ref $class || $class;
	$self->_prepare_diagnostics(%options);
    return $self;
}

sub parse_string {
	my $self = shift;
    my $string = shift;
    my @hash_items = $self->_parse_to_hash($string);
    my @object_items;
    
    foreach my $item (@hash_items) {
	my $error_object = Parse::ErrorString::Perl::ErrorItem->new($item);
	push @object_items, $error_object;
    }
    
    return @object_items;
}

sub _prepare_diagnostics {
	my $self = shift;
	my %options = @_;
	
	my $perldiag;
	my $pod_filename;

	if ($options{lang}) {
		$perldiag = 'POD2::' . $options{lang} . '::perldiag';
		$pod_filename = Pod::Find::pod_where({-inc => 1}, $perldiag);
	
		if (!$pod_filename) {
			carp "Could not locate localised perldiag, trying perldiag in English";
    	}
	}
	
	if (!$pod_filename) {
		$pod_filename = Pod::Find::pod_where({-inc => 1}, 'perldiag');
	
		if (!$pod_filename) {
			carp "Could not locate perldiag, diagnostic info will no be added";
			return;
    	}
	}


	my $parser = Pod::POM->new();
	my $pom = $parser->parse_file($pod_filename);
	if (!$pom) {
		carp $parser->error();
		return;
	}
	
	my %transfmt = (); 
	my $transmo = <<'EOFUNC';
sub transmo {
    study;
EOFUNC
	my %errors;
	foreach my $item ($pom->head1->[1]->over->[0]->item) {
        my $header = $item->title;
		
		my $content = $item->content;
		$content =~ s/\s*$//;
		$errors{$header} = $content;

    

		### CODE FROM SPLAIN
		
		#$header =~ s/[A-Z]<(.*?)>/$1/g;
		
   		my @toks = split( /(%l?[dx]|%c|%(?:\.\d+)?s)/, $header );
		if (@toks > 1) {
    		my $conlen = 0;
        	for my $i (0..$#toks){
	        	if( $i % 2 ) {
		        	if(      $toks[$i] eq '%c' ) {
        	        	$toks[$i] = '.';
	                } elsif( $toks[$i] eq '%d' ) {
		                $toks[$i] = '\d+';
        	        } elsif( $toks[$i] eq '%s' ) {
	        	        $toks[$i] = $i == $#toks ? '.*' : '.*?';
                	} elsif( $toks[$i] =~ '%.(\d+)s' ) {
	                	$toks[$i] = ".{$1}";
		            } elsif( $toks[$i] =~ '^%l*x$' ) {
		                $toks[$i] = '[\da-f]+';
        	        }
				} elsif( length( $toks[$i] ) ) {
	            	$toks[$i] = quotemeta $toks[$i];
	                $conlen += length( $toks[$i] );
    	        }
            }  
            my $lhs = join( '', @toks );
		    $transfmt{$header}{pat} = "    s{^$lhs}\n     {\Q$header\E}s\n\t&& return 1;\n";
            $transfmt{$header}{len} = $conlen;
		} else {
            $transfmt{$header}{pat} = "    m{^\Q$header\E} && return 1;\n";
            $transfmt{$header}{len} = length( $header );
		}
	}

	$self->{errors} = \%errors;

	# Apply patterns in order of decreasing sum of lengths of fixed parts
    # Seems the best way of hitting the right one.
    for my $hdr ( sort { $transfmt{$b}{len} <=> $transfmt{$a}{len} } keys %transfmt ) {
        $transmo .= $transfmt{$hdr}{pat};
    }
    $transmo .= "    return 0;\n}\n";

	# installs a sub named 'transmo', which returns the type of the error message
    eval $transmo;
    carp $@ if $@;
}

sub _get_diagnostics {
	my $self = shift;
	local $_ = shift;
	transmo();
	return $self->{errors}{$_};
}

sub _parse_to_hash {
	my $self = shift;
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
		    file_msgpath    => $2,
			file_abspath => File::Spec->rel2abs($2),
		    line  => $3,
			diagnostics => $self->_get_diagnostics($1),
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
