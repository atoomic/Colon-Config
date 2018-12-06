# NAME

Colon::Config - helper to read a configuration file using ':' as separator

# VERSION

version 0.002

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

## read( $content )

Parse the string $content and return an Array Ref with the list of key/values parsed.

Note: return undef when not called with a string

## read\_as\_hash( $content )

This helper is provided as a convenient feature if want to manipulate the Array Ref
from read as a Hash Ref.

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
