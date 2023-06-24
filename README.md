# Email parser

Based on <https://github.com/josephg/mime-to-jmap> which itself is based on the
Cyrus-IMAP code. C code is extracted from Cyrus and is compiled as part of the
Nim sources.

## Dependencies

- `libicu-devel`
- `libuuid-devel`
- `jansson-devel`

    sudo dnf install libicu-devel libuuid-devel jansson-devel

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
 