# Body.fnl

**Table of contents**

- [`body-reader`](#body-reader)
- [`chunked-body-reader`](#chunked-body-reader)
- [`format-chunk`](#format-chunk)
- [`multipart-body-iterator`](#multipart-body-iterator)
- [`multipart-content-length`](#multipart-content-length)
- [`sized-body-reader`](#sized-body-reader)
- [`stream-body`](#stream-body)
- [`stream-multipart`](#stream-multipart)
- [`wrap-body`](#wrap-body)

## `body-reader`
Function signature:

```
(body-reader src)
```

Read the body part of the request source `src`, with possible
buffering via the `peek` method.

## `chunked-body-reader`
Function signature:

```
(chunked-body-reader src)
```

Reads the body part of the request source `src` in chunks, buffering
each in full, and requesting the next chunk, once the buffer contains
less data than was requested.

## `format-chunk`
Function signature:

```
(format-chunk src)
```

Formats a part of the `src` as a chunk with a calculated size.

## `multipart-body-iterator`
Function signature:

```
(multipart-body-iterator src separator read-headers)
```

Accepts `src`, part `separator` and a `read-headers` function,
building an iterator over multipart request parts.  Each part's
headers are parsed with `read-headers` function.  Returns an iterator,
that in turn returns parts as tables with `headers` table, `type` of
the attachment, `name` and/or `filename` fields, and a `content`
field.  The `content` field is always a `Reader`, and must be
processed before advancing the iterator.  Otherwise, the reader will
be exhausted by the iterator, as it advances to the next part
`separator`.  Once the final separator is met, iterator returns `nil`.

## `multipart-content-length`
Function signature:

```
(multipart-content-length multipart boundary)
```

Calculate the total length of `multipart` body.
Needs to know the `boundary`.

## `sized-body-reader`
Function signature:

```
(sized-body-reader reader bytes)
```

Wraps existing `reader` limiting amount of data that will be read to
`bytes`.

## `stream-body`
Function signature:

```
(stream-body dst body {:content-length content-length :transfer-encoding transfer-encoding})
```

Stream the given `body` to `dst`.
Depending on values of the headers and the type of the `body`, decides
how to stream the data. Streaming from channels and readers requires
the `content-length` field to be present. If the `transfer-encoding`
field specifies a chunked encoding, the body is streamed in chunks.

## `stream-multipart`
Function signature:

```
(stream-multipart dst multipart boundary)
```

Write `multipart` entries to `dst` separated with the `boundary`.

## `wrap-body`
Function signature:

```
(wrap-body body content-type)
```

Wraps `body` in a streamable object.
If the `content-type` is given and is `application/json` and the
`body` is a table it is encoded as JSON reader.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
