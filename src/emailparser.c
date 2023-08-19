// Compile all files together in the same compilation unit so all functions can
// be declared static and do not cause conflict with some other libraries
// included. Some function names are pretty common such as xmalloc.
// See "config.h" for this configuration.

#include "config.h"

#define ensure_alloc ensure_alloc_au
#define adjust_index_ro adjust_index_ro_au
#define adjust_index_rw adjust_index_rw_au
#include "arrayu64.c"
#undef ensure_alloc
#undef adjust_index_ro
#undef adjust_index_rw

#include "charset.c"
#include "chartable.c"
#include "gmtoff_gmtime.c"
#include "gmtoff_tm.c"
#include "hash.c"

#define hash hash_htmlchar
#include "htmlchar.c"
#undef hash

#include "imapparse.c"
#include "imparse.c"
#include "jmap_api.c"
#include "jmap_mail.c"
#include "jmap_mail_query.c"
#include "jmap_util.c"
#include "json_support.c"
#include "mailbox.c"
#include "message.c"
#include "message_guid.c"
#include "mkgmtime.c"
#include "mpool.c"
#include "msgrecord.c"
#include "nim_glue.c"
#include "parseaddr.c"
#include "prot.c"

#define ensure_alloc ensure_alloc_pa
#define adjust_index_ro adjust_index_ro_pa
#define adjust_index_rw adjust_index_rw_pa
#include "ptrarray.c"
#undef ensure_alloc
#undef adjust_index_ro
#undef adjust_index_rw

#include "rfc822_header.c"
#include "rfc822tok.c"
#include "sequence.c"

#define ensure_alloc ensure_alloc_sa
#define adjust_index_ro adjust_index_ro_sa
#define adjust_index_rw adjust_index_rw_sa
#include "strarray.c"
#undef ensure_alloc
#undef adjust_index_ro
#undef adjust_index_rw

#include "strhash.c"
#include "stristr.c"
#include "times.c"
#include "util.c"
#include "xmalloc.c"
#include "xsha1.c"
#include "xstrlcpy.c"

bool emailparser_parse_datetime(
    const char *datetime,
    short *year,
    unsigned short *month,
    unsigned short *day,
    unsigned short *hour,
    unsigned short *minute,
    unsigned short *second,
    unsigned int *nanosecond,
    int *tz_offset_seconds) {
  struct offsettime t;
  int res = offsettime_from_rfc5322(datetime, &t, DATETIME_FULL);
  if (res < 0) return false;
  *year = 1900 + t.tm.tm_year;
  *month = t.tm.tm_mon;
  *day = t.tm.tm_mday;
  *hour = t.tm.tm_hour;
  *minute = t.tm.tm_min;
  *second = t.tm.tm_sec;
  *tz_offset_seconds = t.tm_off;
  return true;
}

int emailparser_datetime_rfc5322_to_iso8601(
    const char *datetime,
    char *buf,
    size_t cap,
    int with_sep) {
  struct offsettime t;
  int res = offsettime_from_rfc5322(datetime, &t, DATETIME_FULL);
  if (res < 0) return res;
  return offsettime_to_iso8601(&t, buf, cap, with_sep);
}

