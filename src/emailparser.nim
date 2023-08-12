{.compile: "emailparser.c".}
{.passc: gorge("icu-config --cppflags").}
{.passl: gorge("icu-config --ldflags").}
{.passl: gorge("pkg-config --libs jansson uuid").}

import std/json
import std/options
import std/strutils
import std/strformat
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

proc header_value(header: string): string =
  result = ""
  var i = 0
  while i < header.len and header[i] != ':':
    i += 1
  if i+1 < header.len:
    result = header[i+1 .. header.len-1]

proc parse_header*(header: string): tuple[name: string, sep: string, raw_value: string] =
  var i = 0
  while i < header.len and header[i] != ':':
    result.name.add(header[i])
    i += 1
  while i < header.len and (header[i] == ':' or header[i] == ' '):
    result.sep.add(header[i])
    i += 1
  if i+1 < header.len:
    result.raw_value = header[i .. header.len-1]

proc parse_header_get_boundary(header: string, boundary: var string): string =
  result = header
  if header_name(header) == "content-type":
    var typ: string
    var subtype: string
    var attrs: TableRef[string,string]
    message_parse_type(header_value(header), typ, subtype, attrs)
    if "BOUNDARY" in attrs:
      boundary = attrs["BOUNDARY"]

type Part* = object
  boundary*: string
  headers*: seq[string]
  crlf*: string
  body*: string # or MIME prologue
  sub_parts*: seq[Part]

func is_start_line(mime: string, i: int): bool =
  return i == 0 or (i > 1 and mime[i-2] == '\r' and mime[i-1] == '\n')

func has_substr_at(mime: string, i: int, sub: string): bool = 
  let j = i + len(sub) - 1
  if j < len(mime):
    return mime[i..j] == sub
  else:
    return false

func has_substr_at_end(mime: string, i: int, sub: string): bool = 
  let j = i + len(sub) - 1
  if j == len(mime) - 1:
    return mime[i..j] == sub
  else:
    return false

type Stop = object
  stop: bool
  boundary: string
  i, j: int
  final: bool

# RFC1341: the start line CRLF is considered to be part of the boundary
func is_stop_boundary(mime: string, i: int, boundaries: seq[string], stop: var Stop): bool =
  # {.nosideeffect.}:
  #   echo &"is_stop_boundary({i}, {mime.substr(i, i+40).repr}, {boundaries})"
  if i != 0 and mime[i] != '\r':
    return false
  for boundary in boundaries:
    if i == 0 and mime[i] == '-':
      if has_substr_at(mime, i, "--" & boundary & "\r\n"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 4, final: false)
        return true
      if has_substr_at(mime, i, "--" & boundary & "--\r\n"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 6, final: true)
        return true
      if has_substr_at_end(mime, i, "--" & boundary & "--"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 4, final: true)
        return true
    if mime[i] == '\r':
      if has_substr_at(mime, i, "\r\n--" & boundary & "\r\n"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 6, final: false)
        return true
      if has_substr_at(mime, i, "\r\n--" & boundary & "--\r\n"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 8, final: true)
        return true
      if has_substr_at_end(mime, i, "\r\n--" & boundary & "--"):
        stop = Stop(stop: true, boundary: boundary, i: i, j: i + len(boundary) + 6, final: true)
        return true
  return false


proc parse_headers(mime: string, i: var int, headers: var seq[string], crlf: var string, body: var string, boundary: var string) =
  headers = @[]
  body = ""
  crlf = ""
  boundary = ""
  var start = 0;
  while i < mime.len:
    # Beginning of line
    if is_start_line(mime, i):
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

proc parse_mime(mime: string, i: var int, boundaries: seq[string], stop: var Stop, part: var Part) =
  part.crlf = ""
  part.body = ""
  part.sub_parts = @[]
  part.headers = @[]

  # Parse headers
  var next_boundary: string = ""
  var body_boundary: string = ""
  var start = i;
  while true:
    if i >= mime.len or is_stop_boundary(mime, i, boundaries, stop):
      if start < i: part.headers.add(parse_header_get_boundary(mime[start .. i-1], body_boundary))
      return
    if is_start_line(mime, i):
      let is_blank_line = has_substr_at(mime, i, "\r\n")
      if is_blank_line:
        if start < i: part.headers.add(parse_header_get_boundary(mime[start .. i-1], body_boundary))
        break
      let is_line_continuation = (mime[i] == ' ' or mime[i] == '\t')
      if not is_line_continuation:
        if start < i: part.headers.add(parse_header_get_boundary(mime[start .. i-1], body_boundary))
        start = i
    i += 1

  # Parse CRLF
  start = i
  assert has_substr_at(mime, i, "\r\n")
  i += 2
  part.crlf = mime[start .. i-1]

  # Parse prologue
  start = i

  let body_delimiter0 = &"--{body_boundary}\r\n"
  if body_boundary != "" and has_substr_at(mime, i, body_delimiter0):
    # Special case, no prologue and single CRLF:
    part.body = ""
    i += len(body_delimiter0)
    next_boundary = mime[start .. i-1]
  else:
    # There is a prologue or at least two CRLF
    let body_delimiter = &"\r\n--{body_boundary}\r\n"
    while true:
      if i >= len(mime) or is_stop_boundary(mime, i, boundaries, stop):
        if start < i:
          part.body = mime[start .. i-1]
        return
      if body_boundary != "" and has_substr_at(mime, i, body_delimiter):
        if start < i: part.body = mime[start .. i-1]
        start = i
        i += len(body_delimiter)
        next_boundary = mime[start .. i-1]
        break
      i += 1

  # Parse parts
  while true:
    var sub_part: Part
    sub_part.boundary = next_boundary
    parse_mime(mime, i, boundaries & @[body_boundary], stop, sub_part)
    part.sub_parts.add(sub_part)

    if i >= mime.len or (stop.stop and stop.boundary != body_boundary):
      return

    next_boundary = mime[stop.i .. stop.j-1]
    i = stop.j

    if stop.final: break

    stop = Stop()

  # Parse epilogue
  stop = Stop()
  start = i
  var sub_part: Part
  sub_part.headers = @[]
  sub_part.crlf = ""
  sub_part.boundary = next_boundary
  sub_part.sub_parts = @[]
  sub_part.body = ""
  while true:
    if i >= len(mime) or is_stop_boundary(mime, i, boundaries, stop):
      if start < i:
        sub_part.body = mime[start .. i-1]
      part.sub_parts.add(sub_part)
      return
    i += 1

proc parse_email*(mime: string): Part =
  var i = 0
  var stop: Stop
  parse_mime(mime, i, @[], stop, result)

proc append_to(part: Part, res: var string) =
  res.add(part.boundary)
  for header in part.headers:
    res.add(header)
  res.add(part.crlf)
  res.add(part.body)

proc to_email*(item: Part): string =
  item.append_to(result)
