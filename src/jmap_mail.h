/* jmap_mail.h -- Routines for handling JMAP mail messages
 *
 * Copyright (c) 1994-2018 Carnegie Mellon University.  All rights reserved.
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
 */

#ifndef JMAP_MAIL_H
#define JMAP_MAIL_H

#include "config.h"

#include <jansson.h>
// #include "hash.h"
// #include "http_jmap.h"
// #include "jmap_util.h"
// #include "json_support.h"
// #include "msgrecord.h"

struct cyrusmsg;

void init_header_parseprops(); // TODO: Add a variant that frees this too.
void init_default_props();
void free_default_props();
int cyrusmsg_from_buf(const struct buf *buf, struct cyrusmsg **msg);
void cyrusmsg_fini(struct cyrusmsg **msgptr);

int jmap_json_from_cyrusmsg(struct cyrusmsg *msg, json_t **jsonOut,
        char *want_headers, char *want_bodyheaders);
char *get_attachment_with_blobid(struct cyrusmsg *msg, const char *buf, size_t expected_size);

// int jmap_email_from_buf(const struct buf *buf,
//                            const char *encoding,
//                            json_t **emailptr);

// extern int jmap_email_find(jmap_req_t *req, const char *email_id,
//                            char **mboxnameptr, uint32_t *uidptr);
// extern int jmap_email_get_with_props(jmap_req_t *req, hash_table *props,
//                                      msgrecord_t *mr, json_t **msgp);

// extern void jmap_emailsubmission_init(jmap_settings_t *settings);
// extern void jmap_emailsubmission_capabilities(json_t *jcapabilities);

// extern void jmap_mailbox_init(jmap_settings_t *settings);
// extern void jmap_mailbox_capabilities(json_t *jcapabilities);

// extern int jmap_mailbox_find_role(jmap_req_t *req, const char *role,
//                                   char **mboxnameptr, char **uniqueid);

#endif /* JMAP_MAIL_H */
