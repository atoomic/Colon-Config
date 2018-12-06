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

{

    # kind of a combo test
    my $content = <<'EOS';
key1:value
key2: value
# a comment

# empty line above
not a column
last:value
EOS

    #note explain Colon::Config::read_pp( $content );

    is Colon::Config::read($content),
        [
        key1 => 'value',
        key2 => 'value',
        last => 'value',
        ],
        "read xs";

}

{
    my $input;

    is Colon::Config::read("key:value\n"), [ 'key', 'value' ], "key:value";
    is Colon::Config::read("key:value"), [ 'key', 'value' ],
        "key:value no newline";

    $input = <<'EOS';
fruit:apple
vegetable:potato
EOS
    is Colon::Config::read($input), [qw/fruit apple vegetable potato/],
        'two set of key/values';

    $input = <<'EOS';
fruit:apple
fruit:orange
EOS
    is Colon::Config::read($input), [qw/fruit apple fruit orange/],
        'duplicate set of key';

    is Colon::Config::read(qq[key:value:with:colon\n]),
        [ 'key', 'value:with:colon' ], "key:value:with:colon";

    $input = qq[extra:newlines\n\n\n\n];
    is Colon::Config::read($input), [ 'extra', 'newlines' ],
        "extra trailing newlines";

    $input = <<EOS;
extra:newlines
with
incomplete
key
values
EOS
    is Colon::Config::read($input), [ 'extra', 'newlines' ],
        "newlines with incomplete keys";

}

done_testing;

__END__
