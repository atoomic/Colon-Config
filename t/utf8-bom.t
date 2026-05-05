#!/usr/bin/perl -w

# Tests for UTF-8 BOM (Byte Order Mark) handling.
# A BOM (EF BB BF) at the start of a file should be transparently
# stripped so it doesn't corrupt the first key.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

my $BOM = "\xEF\xBB\xBF";

# --- XS tests ---

subtest 'XS: BOM at start is stripped from first key' => sub {
    my $input = "${BOM}key:value\n";
    my $result = Colon::Config::read($input);
    is $result, [ 'key', 'value' ], 'BOM stripped, key is clean';
};

subtest 'XS: BOM with multiple entries' => sub {
    my $input = "${BOM}first:one\nsecond:two\n";
    my $result = Colon::Config::read($input);
    is $result, [ 'first', 'one', 'second', 'two' ],
        'BOM only affects start, second entry is fine';
};

subtest 'XS: BOM with leading whitespace' => sub {
    my $input = "${BOM}  key:value\n";
    my $result = Colon::Config::read($input);
    is $result, [ 'key', 'value' ], 'BOM + leading whitespace both stripped';
};

subtest 'XS: BOM with comment line first' => sub {
    my $input = "${BOM}# comment\nkey:value\n";
    my $result = Colon::Config::read($input);
    is $result, [ 'key', 'value' ], 'BOM before comment line handled';
};

subtest 'XS: BOM-only input produces empty result' => sub {
    my $result = Colon::Config::read($BOM);
    is $result, [], 'BOM-only string gives empty arrayref';
};

subtest 'XS: no BOM still works normally' => sub {
    my $input = "key:value\n";
    my $result = Colon::Config::read($input);
    is $result, [ 'key', 'value' ], 'no BOM, normal parsing';
};

subtest 'XS: BOM with field extraction' => sub {
    my $input = "${BOM}root:x:0:0:root:/root:/bin/bash\n";
    my $result = Colon::Config::read($input, 5);
    is $result, [ 'root', '/root' ], 'BOM stripped with field parsing';
};

subtest 'XS: BOM with custom separator' => sub {
    my $input = "${BOM}key;value\n";
    my $result = Colon::Config::read($input, 0, ';');
    is $result, [ 'key', 'value' ], 'BOM stripped with custom separator';
};

# --- PP tests (parity) ---

subtest 'PP: BOM at start is stripped from first key' => sub {
    my $input = "${BOM}key:value\n";
    my $result = Colon::Config::read_pp($input);
    is $result, [ 'key', 'value' ], 'BOM stripped, key is clean';
};

subtest 'PP: BOM with multiple entries' => sub {
    my $input = "${BOM}first:one\nsecond:two\n";
    my $result = Colon::Config::read_pp($input);
    is $result, [ 'first', 'one', 'second', 'two' ],
        'BOM only affects start, second entry is fine';
};

subtest 'PP: BOM with field extraction' => sub {
    my $input = "${BOM}root:x:0:0:root:/root:/bin/bash\n";
    my $result = Colon::Config::read_pp($input, 5);
    is $result, [ 'root', '/root' ], 'BOM stripped with field parsing';
};

subtest 'PP: BOM with custom separator' => sub {
    my $input = "${BOM}key;value\n";
    my $result = Colon::Config::read_pp($input, 0, ';');
    is $result, [ 'key', 'value' ], 'BOM stripped with custom separator';
};

# --- XS/PP parity ---

subtest 'XS/PP parity with BOM' => sub {
    my @inputs = (
        "${BOM}key:value\n",
        "${BOM}first:one\nsecond:two\n",
        "${BOM}# comment\nkey:value\n",
        "${BOM}  key:value\n",
        "${BOM}root:x:0:0\n",
        $BOM,
        "${BOM}\n",
    );

    for my $input (@inputs) {
        my $xs = Colon::Config::read($input);
        my $pp = Colon::Config::read_pp($input);
        my $hex = unpack('H*', substr($input, 0, 20));
        is $pp, $xs, "parity for input starting with: $hex..."
            or diag "XS: " . explain($xs) . "\nPP: " . explain($pp);
    }
};

done_testing;
