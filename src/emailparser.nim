{.compile: "arrayu64.c".}
{.compile: "charset.c".}
{.compile: "chartable.c".}
{.compile: "gmtoff_gmtime.c".}
{.compile: "gmtoff_tm.c".}
{.compile: "hash.c".}
{.compile: "htmlchar.c".}
{.compile: "imapparse.c".}
{.compile: "imparse.c".}
{.compile: "jmap_api.c".}
{.compile: "jmap_mail.c".}
{.compile: "jmap_mail_query.c".}
{.compile: "jmap_util.c".}
{.compile: "json_support.c".}
{.compile: "mailbox.c".}
{.compile: "message.c".}
{.compile: "message_guid.c".}
{.compile: "mkgmtime.c".}
{.compile: "mpool.c".}
{.compile: "msgrecord.c".}
{.compile: "nim_glue.c".}
{.compile: "parseaddr.c".}
{.compile: "prot.c".}
{.compile: "ptrarray.c".}
{.compile: "rfc822_header.c".}
{.compile: "rfc822tok.c".}
{.compile: "sequence.c".}
{.compile: "strarray.c".}
{.compile: "strhash.c".}
{.compile: "stristr.c".}
{.compile: "times.c".}
{.compile: "util.c".}
{.compile: "xmalloc.c".}
{.compile: "xsha1.c".}
{.compile: "xstrlcpy.c".}
{.passc: gorge("icu-config --cppflags").}
{.passl: gorge("icu-config --ldflags").}
{.passl: gorge("pkg-config --libs jansson uuid").}

import std/json
import std/options
import std/strutils
import std/tables

type CyrusMsg {.importc: "struct cyrusmsg".} = object # private

proc init_default_props() {.importc.}
proc init_header_parseprops() {.importc.}

init_default_props()
init_header_parseprops()

proc msg_parse(mime_text: cstring, len: csize_t): ptr CyrusMsg {.importc.}
proc msg_free(msg: ptr CyrusMsg) {.importc.}
proc msg_to_json(msg: ptr CyrusMsg, want_headers: cstring, want_bodyheaders: cstring): cstring {.importc.}
proc msg_get_blob(msg: ptr CyrusMsg, blob_id: cstring, expected_size: csize_t): cstring {.importc.}
proc free(str: pointer) {.importc.}

type struct_param {.importc: "struct param".} = ptr object
  next: struct_param
  attribute: cstring
  value: cstring

proc c_message_parse_type(header: cstring, typep: var cstring, subtypep: var cstring, paramp: var struct_param) {.importc: "message_parse_type".}

proc message_parse_type*(header: string, typ: var string, subtype: var string, param: var TableRef[string,string]) =
  var ctyp: cstring
  var csubtype: cstring
  var cparam: struct_param
  c_message_parse_type(cstring(header), ctyp, csubtype, cparam)
  typ = $ctyp
  free(ctyp)
  subtype = $csubtype
  free(csubtype)
  param = newTable[string,string]()
  while cparam != nil:
    param[$cparam.attribute] = $cparam.value
    let next = cparam.next
    free(cparam.attribute)
    free(cparam.value)
    free(cparam)
    cparam = next

proc envelope_to_jmap(msg: ptr CyrusMsg, want_headers: seq[string] = @[], want_bodyheaders: seq[string] = @[]): JsonNode =
  var arg_headers: string
  var arg_bodyheaders: string
  var carg_headers: cstring = nil
  var carg_bodyheaders: cstring = nil

  if want_headers.len > 0:
    arg_headers = join(want_headers, "\n")
    carg_headers = cstring(arg_headers)
  if want_bodyheaders.len > 0:
    arg_bodyheaders = join(want_bodyheaders, "\n")
    carg_bodyheaders = cstring(arg_bodyheaders)

  let json = msg_to_json(msg, carg_headers, carg_bodyheaders)

  result = parse_json($json)
  free(pointer(json))

proc envelope_to_jmap*(mime_content: string, want_headers: seq[string] = @[], want_bodyheaders: seq[string] = @[]): Option[JsonNode] =
  let msg = msg_parse(mime_content, csize_t(len(mime_content)))

  if msg == nil:
    return none(JsonNode)

  defer: free(pointer(msg))

  return some(envelope_to_jmap(msg, want_headers, want_bodyheaders))


proc envelope_to_jmap*(mime_content: string, attachments: var Table[string, string], want_headers: seq[string] = @[], want_bodyheaders: seq[string] = @[]): Option[JsonNode] =
  let msg = msg_parse(mime_content, csize_t(len(mime_content)))

  if msg == nil:
    return none(JsonNode)

  defer: free(pointer(msg))

  result = some(envelope_to_jmap(msg, want_headers, want_bodyheaders))

  let res_attachs: JsonNode = result.get["attachments"]
  for attach in items(res_attachs):
    let blob_id = attach["blobId"].get_str
    let name    = attach["name"].get_str
    let size    = attach["size"].get_int
    let blob    = msg_get_blob(msg, cstring(blob_id), csize_t(size))
    attachments[blob_id] = $blob

proc header_name(header: string): string =
  result = ""
  var i = 0
  while i < header.len and header[i] != ':':
    result.add(header[i].to_lower_ascii)
    i += 1

proc parse_header_get_boundary(header: string, boundary: var string): string =
  result = header
  if header_name(header) == "content-type":
    var typ: string
    var subtype: string
    var attrs: TableRef[string,string]
    message_parse_type(header, typ, subtype, attrs)
    if "boundary" in attrs:
      boundary = attrs["boundary"]

proc parse_headers(mime: string, headers: var seq[string], crlf: var string, body: var string, boundary: var string) =
  headers = @[]
  body = ""
  crlf = ""
  boundary = ""
  var i = 0
  var start = 0;
  while i < mime.len:
    # Beginning of line
    if i == 0 or mime[i-1] == '\n':
      # Line continuation
      if mime[i] == ' ' or mime[i] == '\t':
        i += 1
        continue

      let is_end_of_headers = i+1 < mime.len and mime[i] == '\r' and mime[i+1] == '\n'

      # This is the start of a header line, save last header first
      if i != 0 and not is_end_of_headers: headers.add(parse_header_get_boundary(mime[start..i-1], boundary))
      start = i

      # End of headers (blank line)
      if is_end_of_headers:
        crlf = mime[i..i+1]
        if i+2 < mime.len: body = mime[i+2..mime.len-1]
        return
    i += 1
  # only headers and no body, fall through the loop, save last header
  if i != 0: headers.add(parse_header_get_boundary(mime[start..i-1], boundary))

