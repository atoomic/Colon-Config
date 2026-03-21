#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Test that read_pp() supports the $field argument, matching XS read() behavior

my $content = <<'EOS';
key1:f1:f2:f3
key2: f1: f2 : f3
key3:::
# a comment

# empty line above
not a column
last:value
EOS

# field=0 (default): everything after first ':'
is Colon::Config::read_pp($content),
    Colon::Config::read($content, 0),
    "read_pp() default matches read() field=0";

is Colon::Config::read_pp($content, 0),
    Colon::Config::read($content, 0),
    "read_pp() field=0 matches read()";

# field=1: first colon-separated field after key
is Colon::Config::read_pp($content, 1),
    Colon::Config::read($content, 1),
    "read_pp() field=1 matches read()";

# field=2
is Colon::Config::read_pp($content, 2),
    Colon::Config::read($content, 2),
    "read_pp() field=2 matches read()";

# field=3
is Colon::Config::read_pp($content, 3),
    Colon::Config::read($content, 3),
    "read_pp() field=3 matches read()";

# field=4 (out of range)
is Colon::Config::read_pp($content, 4),
    Colon::Config::read($content, 4),
    "read_pp() field=4 (out of range) matches read()";

# Simple case from example-fruits.t
my $fruits = <<'EOS';
fruits:apple:banana:orange
veggies:beet:corn:kale
EOS

is Colon::Config::read_pp($fruits, 1),
    Colon::Config::read($fruits, 1),
    "read_pp() fruits field=1 matches read()";

is Colon::Config::read_pp($fruits, 2),
    Colon::Config::read($fruits, 2),
    "read_pp() fruits field=2 matches read()";

is Colon::Config::read_pp($fruits, 99),
    Colon::Config::read($fruits, 99),
    "read_pp() fruits field=99 (out of range) matches read()";

done_testing;
