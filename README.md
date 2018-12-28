# NAME

Colon::Config - XS helper to read a configuration file using ':' as separator

# VERSION

version 0.004

# SYNOPSIS

Colon::Config sample usage

```perl
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

my $array;
is $array = Colon::Config::read($config_sample), [

    # note this is an Array Ref by default
    'fruit'  => 'banana',
    'world'  => 'space',
    'empty'  => undef,
    'sample' => 'value:with:column',
    'last'   => 'value'
  ]
  or diag explain $array;

my $hash;
is $hash = Colon::Config::read_as_hash($config_sample), {
    'fruit'  => 'banana',
    'world'  => 'space',
    'empty'  => undef,
    'sample' => 'value:with:column',
    'last'   => 'value'
  }
  or diag explain $hash;

# you can also read the value from any custom field

my $data = <<EOS;
ali:x:1000:1000:Ali Ben:/home/ali:/bin/zsh
dad:y:1001:1010:Daddy:/home/dad:/bin/bash
mum:z:1002:1010:Mummy::/sbin/nologin
EOS

is $array = Colon::Config::read( $data, 1 ), [
    'ali' => 'x',
    'dad' => 'y',
    'mum' => 'z',
] or diag explain $array;

is $hash = Colon::Config::read_as_hash( $data, 1 ), {
    'ali' => 'x',
    'dad' => 'y',
    'mum' => 'z',
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 2 ), {
    'ali' => 1000,
    'dad' => 1001,
    'mum' => 1002,
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 4 ), {
    'ali' => 'Ali Ben',
    'dad' => 'Daddy',
    'mum' => 'Mummy',
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 5 ), {
    'ali' => '/home/ali',
    'dad' => '/home/dad',
    'mum' => undef,
} or diag explain $hash;

is $hash = Colon::Config::read_as_hash( $data, 99 ), {
    'ali' => undef,
    'dad' => undef,
    'mum' => undef,
} or diag explain $hash;

done_testing;
```

# DESCRIPTION

Colon::Config

XS helper to read a configuration file using ':' as separator
(could be customize later)

This right now pretty similar to a double split like this one

```perl
[ map { ( split( m{:\s+}, $_ ) )[ 0, 1 ] } split( m{\n}, $string ) ];
```

# Basic parsing rules

- ':' is the default character separator between key and value 
- spaces or tab characters after ':' are ignored
- '#' indicates the beginning of a comment line
- spaces or tab characters before a comment '#' are ignored
- '\\n' is used for detecting 'End Of line'

# Available functions

## read( $content, \[ $field=0 \] )

Parse the string $content and return an Array Ref with the list of key/values parsed.
By default the value is the whole string after the first ':'.

But you can also read the value from any custom field, where 1 is the first field after the key...

```perl
#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Colon::Config;

my $data = <<'EOS';
fruits:apple:banana:orange
veggies:beet:corn:kale
EOS

is Colon::Config::read($data), [
    fruits  => 'apple:banana:orange',
    veggies => 'beet:corn:kale',
];

is Colon::Config::read( $data, 0 ), Colon::Config::read($data);

is Colon::Config::read( $data, 1 ), [
    fruits  => 'apple',
    veggies => 'beet',
];

is Colon::Config::read( $data, 2 ), [
    fruits  => 'banana',
    veggies => 'corn',
];

is Colon::Config::read( $data, 99 ), [
    fruits  => undef,
    veggies => undef,
];

done_testing;
```

Note: return undef when not called with a string

## read\_as\_hash( $content, \[ $field=0 \] )

This helper is provided as a convenient feature if you want to manipulate the Array Ref
from read as a Hash Ref.

Similarly to read you can also specify from which field the value should be read.

# Benchmark

Here are some benchmarks to check the advantage of the XS helper, against a pure perl alternative.

```perl
#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;
use Benchmark;

our $DATA;

my $map = {
    read_xs => sub {
        return Colon::Config::read( $DATA );
    },
    read_pp => sub {
        return Colon::Config::read_pp( $DATA ); # limitation on \s+
    },
};

note "sanity check";

foreach my $method ( sort keys %$map ) {

    $DATA = <<EOS;
key1: value
key2: another value
EOS
    is $map->{$method}->(), [ 'key1' => 'value', 'key2' => 'another value' ], "sanity check: '$method'" or die;
}

note "Running benchmark";
for my $size ( 1, 4, 16, 64, 256, 1024 ) {
    note "Using $size key/value pairs\n";

    $DATA = '';
    foreach my $id ( 1..$size ) {
        $DATA .= "key$id: value is $id\n";
    }
    Benchmark::cmpthese( - 5 => $map );
    note "";
}

=pod

        # Using 1 key/value pairs
                     Rate read_pp read_xs
        read_pp  442226/s      --    -75%
        read_xs 1767796/s    300%      --
        #
        # Using 4 key/value pairs
                    Rate read_pp read_xs
        read_pp 172602/s      --    -68%
        read_xs 532991/s    209%      --
        #
        # Using 16 key/value pairs
                    Rate read_pp read_xs
        read_pp  52187/s      --    -64%
        read_xs 145873/s    180%      --
        #
        # Using 64 key/value pairs
                   Rate read_pp read_xs
        read_pp 13307/s      --    -66%
        read_xs 39519/s    197%      --
        #
        # Using 256 key/value pairs
                   Rate read_pp read_xs
        read_pp  3533/s      --    -65%
        read_xs 10228/s    189%      --
        #
        # Using 1024 key/value pairs
                  Rate read_pp read_xs
        read_pp  899/s      --    -60%
        read_xs 2265/s    152%      --

=cut

# checking field

$map = {
    split => sub {
        return { map { ( split(m{:}), 3 )[ 0, 2 ] } split( m{\n}, $DATA ) }
    },

    # colon => sub {
    #     my $a = Colon::Config::read( $DATA );
    #     for ( my $i = 1 ; $i < scalar @$a; $i += 2 ) {
    #         next unless defined $a->[ $i ];
    #         # preserve bogus behavior
    #         #do { $a->[ $i ] = 3; next } unless index( $a->[ $i ], ':' ) >= 0;
    #         # suggested fix
    #         #next unless index( $a->[ $i ], ':' ) >= 0;
    #         $a->[ $i ] = ( split(  ':', $a->[ $i ], 3 ) ) [ 1 ] // 3; # // 3 to preserve bogus behavior
    #     }

    #     return { @$a };
    # },

    field => sub {
        return Colon::Config::read_as_hash( $DATA, 2 );
    },
};

# sanity check
$DATA = <<EOS;
john:f1:f2:f3:f4
cena:f1:f2:f3:f4
EOS

foreach my $method ( sort keys %$map ) {
    is $map->{$method}->(), { john => 'f2', cena => 'f2' }, "testing $method";    
}

note "Running benchmark";
for my $size ( 1, 4, 16, 64, 256, 1024 ) {
    note "Using $size key/value pairs\n";

    $DATA = '';
    foreach my $id ( 1..$size ) {
        $DATA .= "key$id:f1:f2:f3:f4\n";
    }
    Benchmark::cmpthese( - 5 => $map );
    note "";
}

=pod

        # Using 1 key/value pairs
                  Rate split field
        split 563142/s    --   -9%
        field 617929/s   10%    --
        #
        # Using 4 key/value pairs
                  Rate split field
        split 183828/s    --  -30%
        field 261684/s   42%    --
        #
        # Using 16 key/value pairs
                 Rate split field
        split 49493/s    --  -39%
        field 81617/s   65%    --
        #
        # Using 64 key/value pairs
                 Rate split field
        split 12753/s    --  -45%
        field 23247/s   82%    --
        #
        # Using 256 key/value pairs
                Rate split field
        split 3041/s    --  -42%
        field 5237/s   72%    --
        #
        # Using 1024 key/value pairs
                Rate split field
        split  728/s    --  -41%
        field 1235/s   70%    --

=cut

done_testing;

__END__
```

# TODO

- support for custom characters: separator, end of line, spaces, ...

# LICENSE

This software is copyright (c) 2018 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming
language system itself.

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE
OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY
WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

# AUTHOR

Nicolas R <atoomic@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
