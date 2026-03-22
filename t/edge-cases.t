#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# --- Empty / minimal inputs ---

{
    note "empty and minimal inputs";

    is Colon::Config::read(""), [], "empty string returns empty arrayref";
    is Colon::Config::read("\n"), [], "single newline returns empty arrayref";
    is Colon::Config::read("\n\n\n"), [], "multiple newlines returns empty arrayref";
    is Colon::Config::read("   \n"), [], "whitespace-only line returns empty arrayref";
    is Colon::Config::read("\t\t\n"), [], "tabs-only line returns empty arrayref";
    is Colon::Config::read("   \n  \t\n"), [], "whitespace-only lines return empty arrayref";
    is Colon::Config::read("no colon here\n"), [], "line without colon is skipped";
    is Colon::Config::read("no colon"), [], "line without colon (no newline) is skipped";
}

# --- undef / non-string inputs ---

{
    note "undef and non-string inputs";

    is Colon::Config::read(undef), undef, "undef input returns undef";

    # integer input — not a string, should return undef
    my $num = 42;
    is Colon::Config::read($num), undef, "integer input returns undef"
        or diag explain Colon::Config::read($num);
}

# --- Empty key ---

{
    note "empty key (colon at start of line)";

    # A line starting with ':' has an empty key — XS treats end_key == start_key
    # so the line is skipped (no key to push)
    is Colon::Config::read(":value\n"), [], "empty key is skipped";
    is Colon::Config::read(":value\nreal:data\n"), [ 'real', 'data' ],
        "empty key line skipped, valid line parsed";
}

# --- Single key:value ---

{
    note "single key:value";

    is Colon::Config::read("key:value"), [ key => 'value' ], "no trailing newline works";
    is Colon::Config::read("key:value\n"), [ key => 'value' ], "single key:value with newline";
    is Colon::Config::read("no colon\nkey:value\n"),
        [ key => 'value' ],
        "non-colon line skipped, colon line parsed";
}

# --- Empty value ---

{
    note "empty value";

    is Colon::Config::read("key:\n"), [ 'key', undef ],
        "key with empty value returns undef for value";
    is Colon::Config::read("key:  \n"), [ 'key', undef ],
        "key with whitespace-only value returns undef";
    is Colon::Config::read("key:\t\n"), [ 'key', undef ],
        "key with tab-only value returns undef";
}

# --- Consecutive colons ---

{
    note "consecutive colons";

    is Colon::Config::read("key::value\n"), [ 'key', ':value' ],
        "double colon: first colon is separator, rest is value";
    is Colon::Config::read("key:::value\n"), [ 'key', '::value' ],
        "triple colon: first colon is separator";
    is Colon::Config::read("key:::::\n"), [ 'key', '::::' ],
        "key followed by only colons";
}

# --- Whitespace in keys ---

{
    note "whitespace in keys";

    is Colon::Config::read("  key:value\n"), [ 'key', 'value' ],
        "leading spaces in key are trimmed";
    is Colon::Config::read("\tkey:value\n"), [ 'key', 'value' ],
        "leading tab in key is trimmed";
    is Colon::Config::read("key with spaces:value\n"), [ 'key with spaces', 'value' ],
        "spaces within key are preserved";
}

# --- Trailing whitespace in values ---

{
    note "trailing whitespace in values";

    is Colon::Config::read("key:value   \n"), [ 'key', 'value' ],
        "trailing spaces in value are trimmed";
    is Colon::Config::read("key:value\t\n"), [ 'key', 'value' ],
        "trailing tab in value is trimmed";
    is Colon::Config::read("key: value with spaces \n"), [ 'key', 'value with spaces' ],
        "inner spaces preserved, trailing trimmed";
    is Colon::Config::read("key:  value  \n"), [ 'key', 'value' ],
        "value whitespace trimmed";
}

# --- Only comments ---

{
    note "comment-only input";

    is Colon::Config::read("# comment\n"), [], "comment-only input returns empty arrayref";
    is Colon::Config::read("# c1\n# c2\n# c3\n"), [],
        "multiple comment lines returns empty arrayref";
    is Colon::Config::read("  # indented comment\n"), [],
        "indented comment is skipped";
}

# --- Mixed carriage returns ---

{
    note "carriage return handling";

    is Colon::Config::read("key:value\r\n"), [ key => 'value' ], "CRLF line ending";

    # Note: XS skips \r for state machine transitions but preserves raw bytes in values.
    # An embedded \r mid-value is kept in the output (it's not a line ending).
    is Colon::Config::read("key:val\rue\n"), [ key => "val\rue" ],
        "embedded \\r in value preserved by XS";
}

# --- read_as_hash edge cases ---

{
    note "read_as_hash edge cases";

    is Colon::Config::read_as_hash(""), {}, "read_as_hash on empty string returns empty hashref";
    is Colon::Config::read_as_hash("key:value\n"), { key => 'value' }, "read_as_hash basic";
}

# --- read_as_hash with duplicate keys ---

{
    note "read_as_hash with duplicate keys";

    my $input = "key:first\nkey:second\n";
    my $hash = Colon::Config::read_as_hash($input);
    is $hash, { key => 'second' },
        "read_as_hash: last value wins for duplicate keys";

    is Colon::Config::read_as_hash("a:1\nb:2\na:3\n"), { a => '3', b => '2' },
        "read_as_hash with three entries, duplicate key keeps last value";
}

# --- read_as_hash with undef values ---

{
    note "read_as_hash with undef values";

    my $input = "key:\n";
    my $hash = Colon::Config::read_as_hash($input);
    is $hash->{key}, undef, "read_as_hash: empty value is undef";
}

# --- read_as_hash with field ---

{
    note "read_as_hash with field";

    my $content = "root:x:0:0\nnobody:x:99:99\n";

    is Colon::Config::read_as_hash($content, 1), { root => 'x', nobody => 'x' },
        "read_as_hash with field=1";

    is Colon::Config::read_as_hash($content, 2), { root => '0', nobody => '99' },
        "read_as_hash with field=2";
}

# --- Field extraction edge cases ---

{
    note "field extraction edge cases";

    my $input = "a:b:c:d:e\n";

    is Colon::Config::read($input, 0), [ 'a', 'b:c:d:e' ],
        "field=0: full value after first colon";
    is Colon::Config::read($input, 1), [ 'a', 'b' ],
        "field=1: first field";
    is Colon::Config::read($input, 4), [ 'a', 'e' ],
        "field=4: last field";
    is Colon::Config::read($input, 5), [ 'a', undef ],
        "field=5: beyond last field returns undef";
}

# --- Mixed line endings ---

{
    note "mixed line endings in same input";

    my $input = "key1:val1\nkey2:val2\r\nkey3:val3\n";
    is Colon::Config::read($input),
        [ 'key1', 'val1', 'key2', 'val2', 'key3', 'val3' ],
        "mixed \\n and \\r\\n line endings";
}

# --- Last line without newline ---

{
    note "last line without trailing newline";

    is Colon::Config::read("a:1\nb:2"), [ 'a', '1', 'b', '2' ],
        "multiple lines, no trailing newline";
    is Colon::Config::read("a:1\nb:2\nc:3"), [ 'a', '1', 'b', '2', 'c', '3' ],
        "three lines, no trailing newline";
}

# --- XS vs PP parity ---

{
    note "XS vs PP parity on edge cases";

    my @cases = (
        [ "", "empty string" ],
        [ "key:value\n", "simple" ],
        [ "key:\n", "empty value" ],
        [ "# comment\nkey:val\n", "comment then data" ],
        [ "key:val:with:colons\n", "colons in value" ],
        [ "  key:value\n", "leading whitespace" ],
        [ "key:value   \n", "trailing whitespace" ],
        [ "a:1\nb:2\n", "two lines" ],
    );

    for my $case (@cases) {
        my ($input, $desc) = @$case;
        is Colon::Config::read_pp($input), Colon::Config::read($input),
            "XS/PP parity: $desc";
    }

    # Field extraction parity
    my $field_input = "a:b:c:d\n";
    for my $field (0, 1, 2, 3, 4) {
        is Colon::Config::read_pp($field_input, $field),
            Colon::Config::read($field_input, $field),
            "XS/PP parity field=$field";
    }
}

done_testing;
