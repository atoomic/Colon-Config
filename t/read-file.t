#!/usr/bin/perl -w

use strict;
use warnings;
use File::Temp qw(tempfile);

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# Helper: create a temp file with given content
sub write_temp {
    my ($content) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $content;
    close $fh;
    return $path;
}

# --- read_file basics ---

{
    note "read_file basic usage";

    my $path = write_temp("key:value\n");
    is Colon::Config::read_file($path), [ key => 'value' ],
        "read_file basic key:value";
}

{
    my $path = write_temp("fruit:apple\nvegetable:potato\n");
    is Colon::Config::read_file($path),
        [ fruit => 'apple', vegetable => 'potato' ],
        "read_file multiple entries";
}

# --- read_file with field extraction ---

{
    note "read_file with field";

    my $path = write_temp("root:x:0:0:root:/root:/bin/bash\nnobody:x:99:99:Nobody:/:/sbin/nologin\n");

    is Colon::Config::read_file($path, 1),
        [ root => 'x', nobody => 'x' ],
        "read_file field=1";

    is Colon::Config::read_file($path, 2),
        [ root => '0', nobody => '99' ],
        "read_file field=2";

    is Colon::Config::read_file($path, 99),
        [ root => undef, nobody => undef ],
        "read_file field out of range returns undef";
}

# --- read_file with custom separator ---

{
    note "read_file with custom separator";

    my $path = write_temp("key;value\n");
    is Colon::Config::read_file($path, 0, ";"),
        [ key => 'value' ],
        "read_file with semicolon separator";

    my $path2 = write_temp("key=value\nother=data\n");
    is Colon::Config::read_file($path2, 0, "="),
        [ key => 'value', other => 'data' ],
        "read_file with equals separator";
}

# --- read_file with comments and empty lines ---

{
    note "read_file with comments";

    my $content = <<'EOS';
# comment
key1:value1

# another comment
key2:value2
EOS
    my $path = write_temp($content);
    is Colon::Config::read_file($path),
        [ key1 => 'value1', key2 => 'value2' ],
        "read_file skips comments and empty lines";
}

# --- read_file on empty file ---

{
    note "read_file edge cases";

    my $path = write_temp("");
    is Colon::Config::read_file($path), [],
        "read_file on empty file returns empty arrayref";
}

# --- read_file with CRLF ---

{
    my $path = write_temp("key:value\r\nother:data\r\n");
    is Colon::Config::read_file($path),
        [ key => 'value', other => 'data' ],
        "read_file handles CRLF line endings";
}

# --- read_file matches in-memory read() ---

{
    my $content = "fruit:apple\n# comment\nvegetable:potato\nempty:\n";
    my $path = write_temp($content);
    is Colon::Config::read_file($path), Colon::Config::read($content),
        "read_file matches in-memory read()";
}

# --- read_file error on non-existent file ---

{
    note "read_file error handling";

    like(
        dies { Colon::Config::read_file("/non/existent/path.conf") },
        qr/Cannot open/,
        "read_file dies on non-existent file"
    );
}

# --- read_file_as_hash ---

{
    note "read_file_as_hash";

    my $path = write_temp("fruit:apple\nvegetable:potato\n");
    is Colon::Config::read_file_as_hash($path),
        { fruit => 'apple', vegetable => 'potato' },
        "read_file_as_hash basic";
}

{
    my $path = write_temp("root:x:0:0\nnobody:x:99:99\n");
    is Colon::Config::read_file_as_hash($path, 2),
        { root => '0', nobody => '99' },
        "read_file_as_hash with field=2";
}

{
    my $path = write_temp("key;value1\nother;value2\n");
    is Colon::Config::read_file_as_hash($path, 0, ";"),
        { key => 'value1', other => 'value2' },
        "read_file_as_hash with custom separator";
}

{
    my $path = write_temp("");
    is Colon::Config::read_file_as_hash($path), {},
        "read_file_as_hash on empty file returns empty hashref";
}

{
    like(
        dies { Colon::Config::read_file_as_hash("/non/existent/path.conf") },
        qr/Cannot open/,
        "read_file_as_hash dies on non-existent file"
    );
}

# --- read_file_as_hash with duplicate keys ---

{
    my $path = write_temp("key:first\nkey:second\n");
    is Colon::Config::read_file_as_hash($path),
        { key => 'second' },
        "read_file_as_hash: last value wins for duplicate keys";
}

done_testing;
