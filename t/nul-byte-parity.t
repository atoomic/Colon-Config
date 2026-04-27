#!/usr/bin/perl -w

# Tests that NUL bytes (\0) are handled identically by XS and PP.
# XS skips NUL for state transitions (continue) but preserves them in
# pointer ranges. PP must match: strip leading NUL (like whitespace) but
# preserve embedded NUL in keys and values.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Helper: compare XS and PP for a given input
sub parity_ok {
    my ($input, $field, $label) = @_;
    $field = 0 unless defined $field;

    my $xs = Colon::Config::read($input, $field);
    my $pp = Colon::Config::read_pp($input, $field);

    is $pp, $xs, $label
        or diag "XS: [" . join(", ", map { defined $_ ? unpack("H*", $_) : "undef" } @$xs) . "]\n"
               . "PP: [" . join(", ", map { defined $_ ? unpack("H*", $_) : "undef" } @$pp) . "]";
}

# --- NUL in keys ---

parity_ok("k\x00ey:value\n", 0, "NUL embedded in key");
parity_ok("ke\x00y:value\n", 0, "NUL near end of key");
parity_ok("key\x00:value\n", 0, "NUL just before separator");

# --- NUL in values ---

parity_ok("key:val\x00ue\n", 0, "NUL embedded in value");
parity_ok("key:v\x00\x00alue\n", 0, "multiple NUL in value");
parity_ok("key:value\x00\n", 0, "NUL at end of value (before newline)");

# --- Leading NUL (should be stripped like whitespace) ---

parity_ok("\x00key:value\n", 0, "leading NUL stripped from line");
parity_ok("\x00\x00key:value\n", 0, "multiple leading NUL stripped");
parity_ok(" \x00 key:value\n", 0, "mixed space and NUL at line start");

# --- NUL after separator (leading NUL in value stripped) ---

parity_ok("key:\x00value\n", 0, "NUL after separator stripped as leading whitespace");
parity_ok("key:\x00\x00value\n", 0, "multiple NUL after separator stripped");
parity_ok("key: \x00 value\n", 0, "mixed space and NUL after separator");

# --- NUL between lines ---

parity_ok("a:1\n\x00b:2\n", 0, "NUL at start of second line");
parity_ok("a:1\n\x00\nb:2\n", 0, "NUL on its own line");

# --- NUL with field extraction ---

parity_ok("a:b\x00:c\n", 1, "NUL in field 1 value");
parity_ok("a:\x00b:c\n", 1, "NUL before field 1 value");
parity_ok("a:b:c\x00d\n", 2, "NUL in field 2 value");

# --- NUL with custom separator ---

{
    my $xs = Colon::Config::read("k\x00ey;value\n", 0, ";");
    my $pp = Colon::Config::read_pp("k\x00ey;value\n", 0, ";");
    is $pp, $xs, "NUL in key with custom separator";
}

{
    my $xs = Colon::Config::read("key;val\x00ue\n", 0, ";");
    my $pp = Colon::Config::read_pp("key;val\x00ue\n", 0, ";");
    is $pp, $xs, "NUL in value with custom separator";
}

# --- Verify XS behavior directly ---

{
    note "XS preserves embedded NUL in keys";
    my $result = Colon::Config::read("k\x00ey:value\n");
    is length($result->[0]), 4, "key with embedded NUL is 4 bytes";
    is unpack("H*", $result->[0]), "6b006579", "key bytes include NUL";
}

{
    note "XS preserves embedded NUL in values";
    my $result = Colon::Config::read("key:val\x00ue\n");
    is length($result->[1]), 6, "value with embedded NUL is 6 bytes";
    is unpack("H*", $result->[1]), "76616c007565", "value bytes include NUL";
}

{
    note "leading NUL is stripped (not part of key)";
    my $result = Colon::Config::read("\x00key:value\n");
    is $result->[0], "key", "leading NUL stripped from key";
}

done_testing;
