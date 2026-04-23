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

# --- Empty and minimal inputs ---

is Colon::Config::read(""), [], "empty string returns empty arrayref";

is Colon::Config::read(undef), undef, "undef input returns undef";

is Colon::Config::read("\n"), [], "single newline returns empty arrayref";

is Colon::Config::read("\n\n\n"), [], "multiple newlines return empty arrayref";

is Colon::Config::read("   \n  \t\n"), [], "whitespace-only lines return empty arrayref";

# --- Comment-only inputs ---

is Colon::Config::read("# just a comment\n"), [], "comment-only input returns empty arrayref";

is Colon::Config::read("# line 1\n# line 2\n"), [], "multiple comment lines return empty arrayref";

# --- Lines without separator ---

is Colon::Config::read("no separator here\n"), [], "line without colon is skipped";

is Colon::Config::read("no colon\nkey:value\n"),
    [ key => 'value' ],
    "non-colon line skipped, colon line parsed";

is Colon::Config::read("key:value\nno separator"),
    [ key => 'value' ],
    "no-separator line at end (no trailing newline) is skipped";

is Colon::Config::read("no sep 1\nno sep 2\nkey:value\nno sep 3\n"),
    [ key => 'value' ],
    "multiple no-separator lines around a valid line";

# --- Single key:value ---

is Colon::Config::read("key:value"), [ key => 'value' ], "no trailing newline works";

is Colon::Config::read("key:value\n"), [ key => 'value' ], "single key:value with newline";

# --- Empty value ---

is Colon::Config::read("key:\n"), [ key => undef ], "empty value returns undef";

is Colon::Config::read("key:   \n"), [ key => undef ], "whitespace-only value returns undef";

# --- Whitespace handling ---

is Colon::Config::read("  key:value\n"), [ key => 'value' ], "leading whitespace on key trimmed";

is Colon::Config::read("\tkey:value\n"), [ key => 'value' ], "leading tab on key trimmed";

is Colon::Config::read("key:  value  \n"), [ key => 'value' ], "value whitespace trimmed";

# --- Mixed carriage returns ---

is Colon::Config::read("key:value\r\n"), [ key => 'value' ], "CRLF line ending";

# Note: XS skips \r for state machine transitions but preserves raw bytes in values.
# An embedded \r mid-value is kept in the output (it's not a line ending).
is Colon::Config::read("key:val\rue\n"), [ key => "val\rue" ], "embedded \\r in value preserved by XS";

# --- read_as_hash edge cases ---

is Colon::Config::read_as_hash(""), {}, "read_as_hash on empty string returns empty hashref";

is Colon::Config::read_as_hash("key:value\n"), { key => 'value' }, "read_as_hash basic";

is Colon::Config::read_as_hash("a:1\nb:2\na:3\n"), { a => '3', b => '2' },
    "read_as_hash with duplicate keys keeps last value";

# --- read_as_hash with field ---

my $content = "root:x:0:0\nnobody:x:99:99\n";

is Colon::Config::read_as_hash($content, 1), { root => 'x', nobody => 'x' },
    "read_as_hash with field=1";

is Colon::Config::read_as_hash($content, 2), { root => '0', nobody => '99' },
    "read_as_hash with field=2";

done_testing;
