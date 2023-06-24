#include "config.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
// #include <locale.h>

#include "util.h"
#include "jmap_mail.h"
// #include "times.h"

static struct buf warn_out = {};

void log_warning(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    buf_vprintf(&warn_out, fmt, args);
    buf_appendcstr(&warn_out, "\n");

    fwrite(buf_base(&warn_out), buf_len(&warn_out), 1, stderr);
    fprintf(stderr, "\n");
    // vfprintf(stderr, fmt, args);
    va_end(args);
}

void dump_log() {
    if (buf_len(&warn_out)) {
        fprintf(stderr, "Messages:\n%s\n", buf_cstring(&warn_out));
        // buf_reset(&warn_out);
        buf_free(&warn_out);
    }
}

// int cyrusmsg_from_buf(const struct buf *buf, struct cyrusmsg **msg);
// void cyrusmsg_fini(struct cyrusmsg **msgptr);

// int jmap_json_from_cyrusmsg(struct cyrusmsg *msg, json_t **jsonOut);
// int get_attachments_count(struct cyrusmsg *msg);
// struct buf get_attachment_nth(struct cyrusmsg *msg, int i);


__attribute__((__visibility__("default")))
struct cyrusmsg *msg_parse(const char *mime_text, size_t len) {
    // fprintf(stderr, "msg_parse %zd\n", len);
    // struct buf *b = buf_new();
    struct buf b;
    // fwrite(mime_text, len, 1, stderr);

    buf_init_ro(&b, mime_text, len);

    struct cyrusmsg *ret;
    int r = cyrusmsg_from_buf(&b, &ret);
    buf_free(&b);
    dump_log();

    if (r) {
        fprintf(stderr, "Error parsing MIME message %d\n", r);
        return NULL;
    } else {
        return ret;
    }

    // char *j = json_dumps(ret, 0);
    // return j;
}

void msg_free(struct cyrusmsg *msg) {
    cyrusmsg_fini(&msg);
    free_default_props();
}

char *msg_to_json(struct cyrusmsg *msg, char *want_headers, char *want_bodyheaders) {
    json_t *jsonOut;
    int r = jmap_json_from_cyrusmsg(msg, &jsonOut, want_headers, want_bodyheaders);
    dump_log();
    if (r) {
        fprintf(stderr, "Error parsing MIME message to JSON %d\n", r);
        return NULL;
    } else {
        char *ret = json_dumps(jsonOut, JSON_COMPACT | JSON_SORT_KEYS);
        json_decref(jsonOut);
        return ret;
    }
}


char *get_blob_space() {
    static char blobSpace[42] = {};
    return blobSpace;
}

// The blobid should always be a 42 byte long string pulled out of the JSON,
// including \0.
const char *msg_get_blob(struct cyrusmsg *msg, char *blobId, size_t expectedSize) {
    return get_attachment_with_blobid(msg, blobId == NULL ? get_blob_space() : blobId, expectedSize);
}

// Needed to track allocations with the leak checker.
static void m_free(void *ptr) { free(ptr); }

EXPORTED void fatal(const char *s, int code) {
    assert(0);
}