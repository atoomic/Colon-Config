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

ok 1;

my $content = <<'EOS';
key1:value
key2: value
# a comment

# empty line above
not a column
last:value
EOS

#note explain Colon::Config::read_pp( $content );

is Colon::Config::read( $content ),
    [ 
        key1 => 'value',
        key2 => 'value',
        last => 'value',
    ], "read xs";

# note "aaaa: ", explain { @{ Colon::Config::read( $content ) } };

# note "aaaa: ", explain { @{ Colon::Config::read( $content ) } };
# note "aaaa: ", explain { @{ Colon::Config::read( $content ) } };
# note "aaaa: ", explain { @{ Colon::Config::read( $content ) } };
# note "aaaa: ", explain { @{ Colon::Config::read( $content ) } };


done_testing;


__END__

cygwin/cygwin.c-474-    setmntent (0, 0);
cygwin/cygwin.c-475-    while ((mnt = getmntent (0))) {
cygwin/cygwin.c:476:    AV* av = newAV();
cygwin/cygwin.c-477-    av_push(av, newSVpvn(mnt->mnt_dir, strlen(mnt->mnt_dir)));
cygwin/cygwin.c-478-    av_push(av, newSVpvn(mnt->mnt_fsname, strlen(mnt->mnt_fsname)));
cygwin/cygwin.c-479-    av_push(av, newSVpvn(mnt->mnt_type, strlen(mnt->mnt_type)));
cygwin/cygwin.c-480-    av_push(av, newSVpvn(mnt->mnt_opts, strlen(mnt->mnt_opts)));
cygwin/cygwin.c-481-    XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));
cygwin/cygwin.c-482-    }
cygwin/cygwin.c-483-    endmntent (0);
cygwin/cygwin.c-484-    PUTBACK;
cygwin/cygwin.c-485-}