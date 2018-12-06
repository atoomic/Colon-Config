#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Colon::Config;

my $config_sample = <<'EOS';
# this is a comment
fruit:banana
world: space
empty:

# ^^ empty line above is ignored
not a column (ignored)
sample:value:with:column
last:value
EOS

is Colon::Config::read( $config_sample ), [
	# note this is an Array Ref by default
   'fruit' =>  'banana',
   'world' => 'space',
   'empty' => undef,
   'sample' => 'value:with:column',
   'last' => 'value'	
] or diag explain Colon::Config::read( $config_sample );

is Colon::Config::read_as_hash( $config_sample ), {
   'fruit' =>  'banana',
   'world' => 'space',
   'empty' => undef,
   'sample' => 'value:with:column',
   'last' => 'value'	
} or diag explain Colon::Config::read( $config_sample );

done_testing;
