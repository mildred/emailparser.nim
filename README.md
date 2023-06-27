# Email parser

This is a MIME E-mail parser for Nim. It features a basic parser that can parse
big blocks of a MIME multipart message (headers, body, multipart body parts). It
does not parse the inside of the header fields nor handle content encoding.

It also features Cyrus code based on <https://github.com/josephg/mime-to-jmap>
that can parse all specifics of a mail message. The Cyrus code can parse a whole
message and return a JsonNode compatible with the JMAP data structure. It
features text snippets and easy handling of multuipart messages.

Parsing small blocks (a MIME part, a header line, ...) can be performed using
the Cyrus IMAP code but this is not done (except for the Content-Type header
parsing). This is the next thing on the roadmap.

This library was created to be able to split messages in small parts and store
each of those parts in database for later processing.

## Dependencies

- `libicu-devel`
- `libuuid-devel`
- `jansson-devel`

    sudo dnf install libicu-devel libuuid-devel jansson-devel

The Cyrus C code is bundled within the Nim code using the `{.compile.}` pragma.
Only the above dependencies needs to be met to ensure that the C code can
compile. `libicu` is for character set encoding, uuid is probably for generating
unique identifiers and jansson is required to generate the JSON data structure
returned by the library.

## LICENSE

This library contains code from Cyrus, which can trace its origins back to the
dark days at CMU. See COPYING_cyrus for the cyrus license. Some code might be
copyright 2019 Joseph Gentle and the Nim code is copyright 2023 Mildred Ki'Lya.

Permission to use, copy, modify, and/or distribute this software for any purpose
with or without fee is hereby granted, provided that the above copyright notice
and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
THIS SOFTWARE.
 