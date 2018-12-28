/*
*
* Copyright (c) 2018, cPanel, LLC.
* All rights reserved.
* http://cpanel.net
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

/* prototypes */
SV* _parse_string(SV *sv);
SV* _parse_string_field(SV *sv, int field);

SV* _parse_string_field(SV *sv, int field) {
  int len = SvCUR(sv);
  char *ptr = (char *) SvPVX_const(sv); /* todo: preserve the const state of the pointer */
  AV   *av;
  char *start_key, *end_key;
  char *start_val, *end_val;
  char *max;

  int is_utf8 = SvUTF8(sv);

  av = newAV();

  const char eol      = '\n';
  const char sep      = ':'; /* customize it later */
  const char comment  = '#';
  const char line_feed = '\r';

  start_key = ptr;
  end_key   = 0;
  start_val = 0;
  end_val   = 0;

  int found_eol = 1;
  int found_comment = 0;
  int found_sep  = 0;

  for ( max = ptr + len ; ptr < max; ++ptr ) {
    if ( ! *ptr ) continue; /* skip \0 so we can parse binaries strings */
    if ( *ptr == line_feed ) continue; /* ignore \r */

    /* skip all characters in a comment block */
    if ( found_comment ) {
      if ( *ptr == eol )
        found_comment = 0;
      continue;
    }

    if ( found_sep ) {
      if ( *ptr == ' ' || *ptr == '\t' )
        continue;
      found_sep = 0;
      end_val = start_val = ptr;
    }

    /* get to the first valuable char of the line */
    if ( found_eol ) { /* starting a line */
      /* spaces at the beginning of a line */
      if ( *ptr == ' ' || *ptr == '\t' || *ptr == line_feed ) {
        continue;
      }
      if ( *ptr == comment ) {
          found_comment = 1;
          continue;
      }
      /* we have a real character to start the line */
      found_eol = 0;
      start_key = ptr;
      end_key   = 0;
    }

    if ( *ptr == sep ) {
        //printf ("# separator key/value\n" );
        if ( !end_key  ) {
          end_key = ptr;
          found_sep = 1;
        }
    } else if ( *ptr == eol ) {

#define __PARSE_STRING_LINE_FIELD /* reuse code for the last line */ \
        end_val = ptr; \
        if (*end_val == line_feed) end_val = ptr - 1; \
        found_eol = 1; \
\
        /* check if we got a key */ \
        if ( end_key > start_key ) { \
          /* we got a key */ \
          av_push(av, newSVpvn_flags( start_key, (int) (end_key - start_key), is_utf8 )); \
\
          /* remove the line_feed chars if any */ \
          while ( end_val > start_val && *(end_val - 1) == line_feed ) {\
            --end_val;\
          }\
          /* only add the value if we have a key */ \
          if ( end_val > start_val ) { \
            av_push(av, newSVpvn_flags( start_val, (int) (end_val - start_val), is_utf8 )); \
          } else { \
            av_push(av, &PL_sv_undef); \
          } \
        } \
/* end of __PARSE_STRING_LINE_FIELD */        

        __PARSE_STRING_LINE_FIELD

        start_key = 0;
    }

  } /* end main for loop for *ptr */

  /* handle the last entry */
  if ( start_key ) {
      __PARSE_STRING_LINE_FIELD
  }

  return (SV*) (newRV_noinc((SV*) av));
}

/* functions */
SV* _parse_string(SV *sv) {
  int len = SvCUR(sv);
  char *ptr = (char *) SvPVX_const(sv); /* todo: preserve the const state of the pointer */
  AV   *av;
  char *start_key, *end_key;
  char *start_val, *end_val;

  int is_utf8 = SvUTF8(sv);

  av = newAV();

  const char eol      = '\n';
  const char sep      = ':'; /* customize it later */
  const char comment  = '#';
  const char line_feed = '\r';

  start_key = ptr;
  end_key   = 0;
  start_val = 0;
  end_val   = 0;

  int found_eol = 1;
  int found_comment = 0;
  int found_sep  = 0;

  for ( char *max = ptr + len ; ptr < max; ++ptr ) {
    if ( ! *ptr ) continue; /* skip \0 */
    if ( *ptr == line_feed ) continue; /* ignore \r */

    /* skip all characters in a comment block */
    if ( found_comment ) {
      if ( *ptr == eol )
        found_comment = 0;
      continue;
    }

    if ( found_sep ) {
      if ( *ptr == ' ' || *ptr == '\t' )
        continue;
      found_sep = 0;
      end_val = start_val = ptr;
    }

    /* get to the first valuable char of the line */
    if ( found_eol ) { /* starting a line */
      /* spaces at the beginning of a line */
      if ( *ptr == ' ' || *ptr == '\t' || *ptr == line_feed ) {
        continue;
      }
      if ( *ptr == comment ) {
          found_comment = 1;
          continue;
      }
      /* we have a real character to start the line */
      found_eol = 0;
      start_key = ptr;
      end_key   = 0;
    }

    if ( *ptr == sep ) {
        //printf ("# separator key/value\n" );
        if ( !end_key  ) {
          end_key = ptr;
          found_sep = 1;
        }
    } else if ( *ptr == eol ) {

#define __PARSE_STRING_LINE /* reuse code for the last line */ \
        end_val = ptr; \
        if (*end_val == line_feed) end_val = ptr - 1; \
        found_eol = 1; \
\
        /* check if we got a key */ \
        if ( end_key > start_key ) { \
          /* we got a key */ \
          av_push(av, newSVpvn_flags( start_key, (int) (end_key - start_key), is_utf8 )); \
\
          /* remove the line_feed chars if any */ \
          while ( end_val > start_val && *(end_val - 1) == line_feed ) {\
            --end_val;\
          }\
          /* only add the value if we have a key */ \
          if ( end_val > start_val ) { \
            av_push(av, newSVpvn_flags( start_val, (int) (end_val - start_val), is_utf8 )); \
          } else { \
            av_push(av, &PL_sv_undef); \
          } \
        } \
/* end of __PARSE_STRING_LINE */        

        __PARSE_STRING_LINE

        start_key = 0;
    }

  } /* end main for loop for *ptr */

  /* handle the last entry */
  if ( start_key ) {
      __PARSE_STRING_LINE
  }

  return (SV*) (newRV_noinc((SV*) av));
}


MODULE = Colon__Config       PACKAGE = Colon::Config

SV*
read_field(sv, field)
  SV *sv;
  int field;
CODE:
  if ( sv && SvPOK(sv) ) {
    RETVAL = _parse_string_field( sv, field );
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL

SV*
read(sv)
  SV *sv;
CODE:
  if ( sv && SvPOK(sv) ) {
    RETVAL = _parse_string( sv );
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL