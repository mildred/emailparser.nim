/* strarray.h -- an expanding array of strings
 *
 * Copyright (c) 1994-2011 Carnegie Mellon University.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The name "Carnegie Mellon University" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For permission or any legal
 *    details, please contact
 *      Carnegie Mellon University
 *      Center for Technology Transfer and Enterprise Creation
 *      4615 Forbes Avenue
 *      Suite 302
 *      Pittsburgh, PA  15213
 *      (412) 268-7393, fax: (412) 268-7395
 *      innovation@andrew.cmu.edu
 *
 * 4. Redistributions of any form whatsoever must retain the following
 *    acknowledgment:
 *    "This product includes software developed by Computing Services
 *     at Carnegie Mellon University (http://www.cmu.edu/computing/)."
 *
 * CARNEGIE MELLON UNIVERSITY DISCLAIMS ALL WARRANTIES WITH REGARD TO
 * THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS, IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY BE LIABLE
 * FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * Author: Greg Banks
 * Start Date: 2011/01/11
 */

#ifndef __CYRUS_STRARRAY_H__
#define __CYRUS_STRARRAY_H__

#include <string.h>
#include <sys/types.h>

typedef struct
{
    int count;
    int alloc;
    char **data;
} strarray_t;

#define STRARRAY_INITIALIZER    { 0, 0, NULL }
#define strarray_init(sa)   (memset((sa), 0, sizeof(strarray_t)))
EXTERN
void strarray_fini(strarray_t *);

EXTERN
strarray_t *strarray_new(void);
EXTERN
void strarray_free(strarray_t *);

EXTERN
int strarray_append(strarray_t *, const char *);
EXTERN
int strarray_add(strarray_t *, const char *);
EXTERN
int strarray_add_case(strarray_t *, const char *);
EXTERN
int strarray_appendm(strarray_t *, char *);
EXTERN
void strarray_set(strarray_t *, int idx, const char *);
EXTERN
void strarray_setm(strarray_t *, int idx, char *);
EXTERN
void strarray_insert(strarray_t *, int idx, const char *);
EXTERN
void strarray_insertm(strarray_t *, int idx, char *);
EXTERN
char *strarray_remove(strarray_t *, int idx);
EXTERN
void strarray_remove_all(strarray_t *sa, const char *s);
EXTERN
void strarray_remove_all_case(strarray_t *sa, const char *s);
EXTERN
const char *strarray_nth(const strarray_t *sa, int idx);
EXTERN
const char *strarray_safenth(const strarray_t *sa, int idx);
EXTERN
void strarray_truncate(strarray_t *sa, int newlen);
EXTERN
strarray_t *strarray_dup(const strarray_t *);
EXTERN
void strarray_cat(strarray_t *dest, const strarray_t *src);
EXTERN
void strarray_swap(strarray_t *, int, int);
EXTERN
void strarray_addfirst(strarray_t *, const char *);
EXTERN
void strarray_addfirst_case(strarray_t *, const char *);

#define strarray_shift(sa)          strarray_remove((sa), 0)
#define strarray_unshift(sa, s)     strarray_insert((sa), 0, (s))
#define strarray_unshiftm(sa, s)    strarray_insertm((sa), 0, (s))

#define strarray_pop(sa)            strarray_remove((sa), -1)
#define strarray_push(sa, s)        strarray_append((sa), (s))
#define strarray_pushm(sa, s)       strarray_appendm((sa), (s))

EXTERN
char *strarray_join(const strarray_t *, const char *sep);
#define STRARRAY_TRIM (1<<0)
EXTERN
strarray_t *strarray_splitm(char *buf, const char *sep, int flags);
EXTERN
strarray_t *strarray_split(const char *buf, const char *sep, int flags);
EXTERN
strarray_t *strarray_nsplit(const char *buf, size_t len, const char *sep, int flags);

/* strarray_cmp_fn_t is same sig as qsort's compar argument */
typedef int strarray_cmp_fn_t(const void *, const void *);
EXTERN
void strarray_sort(strarray_t *, strarray_cmp_fn_t *);

EXTERN
void strarray_uniq(strarray_t *);

EXTERN
char **strarray_safetakevf(strarray_t *sa);
EXTERN
char **strarray_takevf(strarray_t *sa);

EXTERN
int strarray_find(const strarray_t *sa, const char *match,
                  int starting);
EXTERN
int strarray_find_case(const strarray_t *sa, const char *match,
                       int starting);

EXTERN
int strarray_intersect(const strarray_t *sa, const strarray_t *b);
EXTERN
int strarray_intersect_case(const strarray_t *sa, const strarray_t *b);

EXTERN
int strarray_size(const strarray_t *sa);

EXTERN
int strarray_cmp(const strarray_t *a, const strarray_t *b);

#endif /* __CYRUS_STRARRAY_H__ */
