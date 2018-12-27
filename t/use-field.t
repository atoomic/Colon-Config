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
key1:f1:f2:f3
key2: f1: f2 : f3
key3::::::
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
        key3 => ':::::',
        last => 'value',
        ],
        "read default field";

}

done_testing;

__END__
