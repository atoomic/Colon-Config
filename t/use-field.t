#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

#use Test::More;
use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# kind of a combo test
my $content = <<'EOS';
key1:f1:f2:f3
key2: f1: f2 : f3
key3:::
# a comment

# empty line above
not a column
last:value
EOS

#note explain Colon::Config::read_pp( $content );

is Colon::Config::read_field( $content, 0 ),
    [
    key1 => 'f1:f2:f3',
    key2 => 'f1: f2 : f3',
    key3 => '::',
    last => 'value',
    ],
    "read default field=0";

my $a = Colon::Config::read_field( $content, 1 );
is $a,
    [
    key1 => 'f1',
    key2 => 'f1',
    key3 => undef,
    last => 'value',
    ],
    "read field=1" or diag explain { @$a };


$a = Colon::Config::read_field( $content, 2 );
is $a,
    [
    key1 => 'f2',
    key2 => 'f2',
    key3 => undef,
    last => undef,
    ],
    "read field=2" or diag explain { @$a };

$a = Colon::Config::read_field( $content, 3 );
is $a,
    [
    key1 => 'f3',
    key2 => 'f3', # spaces are trim after one op...
    key3 => undef,
    last => undef,
    ],
    "read field=3" or diag explain { @$a };

$a = Colon::Config::read_field( $content, 4 );
is $a,
    [
    key1 => undef,
    key2 => undef, # trim the space
    key3 => undef,
    last => undef,
    ],
    "read field=4" or diag explain { @$a };




done_testing;

__END__
            ( ( *(end_val - 1) == line_feed ) || ( *(end_val - 1) == ' ' ) || ( *(end_val - 1) == '\t' ) ) \