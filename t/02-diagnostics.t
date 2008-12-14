#!perl -T

use lib '../lib';

use Test::Simple tests => 2;
use Parse::ErrorString::Perl;


# use strict;
# use warnings;
#
# $hell;

my $msg_compile = <<'ENDofMSG';
Global symbol "$hell" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my $diagnostics = <<'ENDofMSG';
(F) You've said "use strict" or "use strict vars", which indicates 
that all variables must either be lexically scoped (using "my" or "state"), 
declared beforehand using "our", or explicitly qualified to say 
which package the global variable is in (using "::").
ENDofMSG

my $parser = Parse::ErrorString::Perl->new;
my @errors_compile = $parser->parse_string($msg_compile);
ok($errors_compile[0]->message == 'Global symbol "$hell" requires explicit package name', 'msg_compile message');
ok($errors_compile[0]->diagnostics == $diagnostics);

