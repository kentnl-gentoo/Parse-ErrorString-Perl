#!perl -T

use lib '../lib';

use Test::Simple tests => 22;
use Parse::ErrorString::Perl;

my $parser = Parse::ErrorString::Perl->new;

# use strict;
# use warnings;
#
# $hell;

my $msg_compile = <<'ENDofMSG';
Global symbol "$hell" requires explicit package name at error.pl line 8.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_compile = $parser->parse_string($msg_compile);
ok(@errors_compile, 'msg_compile results');
ok($errors_compile[0]->message == 'Global symbol "$hell" requires explicit package name', 'msg_compile message');
ok($errors_compile[0]->file == 'error.pl', 'msg_compile file');
ok($errors_compile[0]->line == 8, 'msg_compile line');


# use strict;
# use warnings;
#
# my $empty;
# my $length = length($empty);
#
# my $zero = 0;
# my $result = 5 / 0;

my $msg_runtime = <<'ENDofMSG';
Use of uninitialized value $empty in length at error.pl line 5.
Illegal division by zero at error.pl line 8.
ENDofMSG

my @errors_runtime = $parser->parse_string($msg_runtime);
ok(@errors_runtime, 'msg_runtime results');
ok($errors_runtime[0]->message == 'Use of uninitialized value $empty in length', 'msg_runtime 1 message');
ok($errors_runtime[0]->file == 'error.pl', 'msg_runtime 1 file');
ok($errors_runtime[0]->line == 5, 'msg_runtime 1 line');
ok($errors_runtime[1]->message == 'Illegal division by zero', 'msg_runtime 2 message');
ok($errors_runtime[1]->file == 'error.pl', 'msg_runtime 2 file');
ok($errors_runtime[1]->line == 8, 'msg_runtime 2 line');

# use strict;
# use warnings;
#
# my $string = 'tada';
# kaboom
#
# my $length = 5;

my $msg_near = <<'ENDofMSG';
syntax error at error2.pl line 7, near "kaboom

my "
Global symbol "$length" requires explicit package name at error.pl line 7.
Execution of error.pl aborted due to compilation errors.
ENDofMSG

my @errors_near = $parser->parse_string($msg_near);
ok(@errors_near, 'msg_near results');
ok($errors_near[0]->message == 'syntax error', 'msg_near 1 message');
ok($errors_near[0]->file == 'error.pl', 'msg_near 1 file');
ok($errors_near[0]->line == 7, 'msg_near 1 line');
ok($errors_near[1]->message == 'Global symbol "$length" requires explicit package name', 'msg_near 2 message');
ok($errors_near[1]->file == 'error.pl', 'msg_near 2 file');
ok($errors_near[1]->line == 7, 'msg_near 2 line');

# use strict;
# use warnings;
# use diagnostics;
#
# $hell;

my $msg_diagnostics = <<'ENDofMSG';
Global symbol "$hell" requires explicit package name at error.pl line 5.
Execution of error2.pl aborted due to compilation errors (#1)
    (F) You've said "use strict" or "use strict vars", which indicates
    that all variables must either be lexically scoped (using "my" or "state"),
    declared beforehand using "our", or explicitly qualified to say
    which package the global variable is in (using "::").

Uncaught exception from user code:
        Global symbol "$hell" requires explicit package name at error.pl line 5.
Execution of error.pl aborted due to compilation errors.
 at error2.pl line 6
ENDofMSG

my @errors_diagnostics = $parser->parse_string($msg_diagnostics);
ok(@errors_diagnostics, 'msg_diagnostics results');
ok($errors_diagnostics[0]->message == 'syntax Global symbol "$hell" requires explicit package name', 'msg_diagnostics 1 message');
ok($errors_diagnostics[0]->file == 'error.pl', 'msg_diagnostics 1 file');
ok($errors_diagnostics[0]->line == 5, 'msg_diagnostics 1 line');
