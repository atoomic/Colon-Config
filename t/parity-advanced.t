#!/usr/bin/perl -w

# Advanced XS/PP parity tests.
# Covers edge cases identified through deep analysis of the parser state machine
# that are not tested by the basic parity.t suite:
#   - whitespace-only keys
#   - CR-only line endings (old Mac Classic format)
#   - field extraction with consecutive separators (empty fields)
#   - trailing separators
#   - hash character in non-comment positions
#   - custom separator XS/PP parity
#   - large field indices
#   - separator-only lines

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Helper: compare XS and PP for a given input, field, and optional separator
sub parity_ok {
    my ($input, $field, $sep, $label) = @_;
    if (!defined $label) {
        $label = $sep;
        $sep   = undef;
    }
    $field = 0 unless defined $field;

    my $xs = defined $sep
        ? Colon::Config::read($input, $field, $sep)
        : Colon::Config::read($input, $field);
    my $pp = defined $sep
        ? Colon::Config::read_pp($input, $field, $sep)
        : Colon::Config::read_pp($input, $field);

    is $pp, $xs, $label
        or diag "XS: " . explain($xs) . "\nPP: " . explain($pp);
}

# ===== Whitespace-only keys =====

parity_ok("   :value\n",       0, "whitespace-only key (spaces) is skipped");
parity_ok("\t\t:value\n",      0, "whitespace-only key (tabs) is skipped");
parity_ok(" \t :value\n",      0, "whitespace-only key (mixed) is skipped");
parity_ok("   :value\nkey:val\n", 0, "whitespace key then normal entry");

# ===== Hash character in non-comment positions =====

parity_ok("key#name:value\n",          0, "hash in middle of key");
parity_ok("key:val#ue\n",              0, "hash in middle of value");
parity_ok("key:value # not a comment\n", 0, "hash mid-value with spaces");
parity_ok("key:#hashtag\n",            0, "value starting with hash");
parity_ok("  key:#value\n",            0, "indented key, value starting with hash");

# ===== CR-only line endings (no \n) =====

parity_ok("key:value\r",               0, "trailing CR only (no LF)");
parity_ok("key1:val1\rkey2:val2",      0, "CR-only separating lines (no LF)");
parity_ok("key1:val1\r\rkey2:val2\n",  0, "double CR before LF");
parity_ok("key:val\r\r\r\n",           0, "multiple trailing CRs before LF");

# ===== Field extraction with consecutive separators =====

parity_ok("a::c\n",            1, "consecutive separators field=1 (empty field)");
parity_ok("a::c\n",            2, "consecutive separators field=2");
parity_ok("a:::d\n",           1, "triple separator field=1");
parity_ok("a:::d\n",           2, "triple separator field=2");
parity_ok("a:::d\n",           3, "triple separator field=3");
parity_ok("a:b::d\n",          1, "empty middle field, field=1");
parity_ok("a:b::d\n",          2, "empty middle field, field=2");
parity_ok("a:b::d\n",          3, "empty middle field, field=3 (out of range)");

# ===== Trailing separators =====

parity_ok("key:value:\n",      0, "trailing separator field=0");
parity_ok("key:value:\n",      1, "trailing separator field=1");
parity_ok("key:value:\n",      2, "trailing separator field=2 (empty)");
parity_ok("key:value:\n",      3, "trailing separator field=3 (out of range)");
parity_ok("key:\n",            0, "separator with empty value");
parity_ok("key:\n",            1, "separator with empty value field=1");

# ===== Separator-only lines =====

parity_ok(":\n",                0, "separator-only line");
parity_ok("::\n",               0, "double separator line");
parity_ok(":::\n",              0, "triple separator line");
parity_ok(":value\n",           0, "separator at line start (empty key)");
parity_ok(":\nkey:val\n",       0, "separator-only then normal line");

# ===== Large field indices =====

my $multifield = "a:b:c:d:e:f:g:h:i:j\n";
for my $f (0, 1, 5, 9, 10, 50) {
    parity_ok($multifield, $f, "10-field line, field=$f");
}

# ===== Custom separator parity =====

parity_ok("key;value\n",       0, ";", "semicolon separator");
parity_ok("key=value\n",       0, "=", "equals separator");
parity_ok("key|value\n",       0, "|", "pipe separator");
parity_ok("key\tvalue\n",      0, "\t", "tab separator");

# Custom separator with field extraction
parity_ok("a;b;c;d\n",         0, ";", "semicolon field=0");
parity_ok("a;b;c;d\n",         1, ";", "semicolon field=1");
parity_ok("a;b;c;d\n",         2, ";", "semicolon field=2");
parity_ok("a;b;c;d\n",         3, ";", "semicolon field=3");
parity_ok("a;b;c;d\n",         4, ";", "semicolon field=4 (out of range)");

# Custom separator with consecutive separators
parity_ok("a;;c\n",            1, ";", "consecutive semicolons field=1");
parity_ok("a;;c\n",            2, ";", "consecutive semicolons field=2");

# Custom separator preserves colons in values
parity_ok("key;value:with:colons\n", 0, ";", "colons preserved with semicolon sep");

# ===== Mixed line endings in field extraction =====

parity_ok("a:b:c\r\nd:e:f\n",  1, "CRLF with field extraction field=1");
parity_ok("a:b:c\r\nd:e:f\n",  2, "CRLF with field extraction field=2");

# ===== Values that are the separator character =====

parity_ok("key::\n",           1, "value IS the separator (field=1 empty)");

# ===== Input without trailing newline =====

parity_ok("key:value",         0, "no trailing newline");
parity_ok("a:1\nb:2",          0, "last line without newline");
parity_ok("a:1:2\nb:3:4",      1, "last line without newline field=1");
parity_ok("a:1:2\nb:3:4",      2, "last line without newline field=2");

# ===== Multiple entries with various edge cases combined =====

my $complex = join("\n",
    "# header comment",
    "  name:  Alice  ",
    "",
    "  # indented comment",
    "role:admin",
    "path:/usr/local/bin",
    "empty:",
    ":no_key",
    "url:http://example.com#anchor",
    "multi:a:b:c:d",
    "last:value",
) . "\n";

parity_ok($complex, 0, "complex mixed input field=0");
parity_ok($complex, 1, "complex mixed input field=1");

done_testing;
