# Body.fnl

**Table of contents**

- [`body-reader`](#body-reader)
- [`chunked-body-reader`](#chunked-body-reader)
- [`format-chunk`](#format-chunk)
- [`multipart-content-length`](#multipart-content-length)
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

## `multipart-content-length`
Function signature:

```
(multipart-content-length multipart boundary)
```

Calculate the total length of `multipart` body.
Needs to know the `boundary`.

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
