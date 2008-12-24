#!perl -T

use Test::More tests => 4;
use Parse::ErrorString::Perl;
use File::Spec;

my $parser = Parse::ErrorString::Perl->new;

my $msg_short_script = <<'ENDofMSG';
Use of uninitialized value $empty in length at c:\my\very\long\path\to\this\perl\script\called\error.pl line 6.
ENDofMSG

my @errors_short_script = $parser->parse_string($msg_short_script);
ok(@errors_short_script, 'msg_short_script results');
ok($errors_short_script[0]->file eq 'error.pl', 'msg_short_script short path');

our @INC;
my $path = File::Spec->catfile($INC[0], 'Error.pm');
my $msg_short_module = 'Use of uninitialized value $empty in length at ' . $path . ' line 6.';

my @errors_short_module = $parser->parse_string($msg_short_module);
ok(@errors_short_module, 'msg_short_module results');
ok($errors_short_module[0]->file eq 'Error.pm', 'msg_short_module short path');
