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
SV* _parse_string(const char *str);


/* functions */
SV* _parse_string(const char *str) {
  char *ptr = str;
  AV   *av;
  char *start_key, *end_key;
  char *start_val, *end_val;

  av = newAV();

  char eol      = '\n';
  char sep      = ':'; /* customize it later */
  char comment  = '#';

  start_key = ptr;
  end_key   = 0;
  start_val = 0;
  end_val   = 0;

  int start_line = 1;
  int in_comment = 0;
  int found_sep  = 0;
  

  for ( ; *ptr ; ++ptr ) {
    //PerlIO_printf( PerlIO_stderr(), "# C %c\n", *ptr );
    //printf("# char %c\n", *ptr );

    /* skip all characters in a comment block */
    if ( in_comment ) {
      if ( *ptr == eol )
        in_comment = 0;
      continue;
    }

    if ( found_sep ) {
      if ( *ptr == ' ' || *ptr == '\t' )
        continue;
      found_sep = 0;
      end_val = start_val = ptr;
    }

    /* get to the first valuable char of the line */
    if ( start_line ) {
      /* spaces at the beginning of a line */
      if ( *ptr == ' ' || *ptr == '\t' ) {
        continue;
      }
      if ( *ptr == comment ) {
          in_comment = 1;
          continue;
      }
      /* we have a real character to start the line */
      start_line = 0;
      start_key = ptr;
      end_key   = 0;
    }

    if ( *ptr == sep ) {
        //printf ("# separator key/value\n" );
        end_key = ptr - 1;
        found_sep = 1;
        //end_val = start_val = ptr + 1;
    } else if ( *ptr == eol ) {
        end_val = ptr - 1;
        start_line = 1;

        /* check if we got a key */
        if ( end_key > start_key ) {
          /* we got a key */
          av_push(av, newSVpv( start_key, (int) (end_key - start_key) + 1 ));
        
          /* only add the value if we have a key */
          if ( end_val > start_val ) {
            av_push(av, newSVpv( start_val, (int) (end_val - start_val) + 1 ));
          } else {
            av_push(av, &PL_sv_undef);  
          }
          

        }

    }

  } /* end main for loop for *ptr */

  // av_push(av, newSVpv("END",3));
  // av_push(av, newSVpv("END",3));

  return (SV*) (newRV_noinc((SV*) av));
  //return (SV*) sv_2mortal(newRV_noinc((SV*) av));
}


MODULE = Colon__Config       PACKAGE = Colon::Config

SV*
get_basetime()
CODE:
  RETVAL = newSViv(PL_basetime);
OUTPUT:
  RETVAL

SV*
read(content)
  SV *content;
CODE:
  if ( content && SvPOK(content) ) {
    RETVAL = _parse_string( SvPVX_const( content ) );
  } else {
    RETVAL = &PL_sv_undef;
  }
OUTPUT:
  RETVAL