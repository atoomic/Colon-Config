# NAME

Colon::Config - helper to read a configuration file using ':' as separator

# VERSION

version 0.001

# SYNOPSIS

Colon::Config sample usage

```perl
#!perl

use strict;
use warnings;

use strict;
use warnings;

use Test::More;
use Overload::FileCheck q{:all};

my @exist     = qw{cherry banana apple};
my @not_there = qw{not-there missing-file};

mock_all_file_checks( \&my_custom_check );

sub my_custom_check {
    my ( $check, $f ) = @_;

    if ( $check eq 'e' || $check eq 'f' ) {
        return CHECK_IS_TRUE  if grep { $_ eq $f } @exist;
        return CHECK_IS_FALSE if grep { $_ eq $f } @not_there;
    }

    return CHECK_IS_FALSE if $check eq 'd' && grep { $_ eq $f } @exist;

    # fallback to the original Perl OP
    return FALLBACK_TO_REAL_OP;
}

foreach my $f (@exist) {
    ok( -e $f,  "-e $f is true" );
    ok( -f $f,  "-f $f is true" );
    ok( !-d $f, "-d $f is false" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "-e $f is false" );
    ok( !-f $f, "-f $f is false" );
}

unmock_all_file_checks();

done_testing;
```

# DESCRIPTION

Colon::Config

helper to read a configuration file using ':' as separator
(could be customize later)

# Usage and Examples

todo

# TODO

- support for custom characters

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
