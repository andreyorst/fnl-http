# Parser.fnl

**Table of contents**

- [`parse-http-request`](#parse-http-request)
- [`parse-http-response`](#parse-http-response)
- [`parse-url`](#parse-url)
- [`read-headers`](#read-headers)

## `parse-http-request`
Function signature:

```
(parse-http-request src)
```

Parses the HTTP/1.1 request read from `src`.

If the request contained a body, it is returned as a `Reader` under
the `content` key.  Chunked encoding is supported by using a special
`chunked-body-reader`.

If the request had Content Type set to `multipart/*`, the `parts` key
is used, and contains an iterator function, that will iterate over
each part in the request.  Each part is a table with its respective
headers, anc a `content` key, containing a `Reader` object.

Each part's content must be processed or copied before moving to the
next part, as moving to the next part consumes the body data from
`src`.  Note, that when the part doesn't specify any content length or
chunked encoding ther content Reader is not limited to part's contents
and can read into the next part. If that's the case, parts have to be
dumped line by line and analyzed manually.

Returns a table with request `status`, `method`, `http-version`,
`headers` keys, including `content` or `parts` keys if payload was
provided, as described above.

## `parse-http-response`
Function signature:

```
(parse-http-response src {:as as :method method :start start :time time})
```

Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `read`
method.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

`as` is a string, describing how to coerse the response body.  It can
be one of `"raw"`, `"stream"`, or `"json"`.

`start` is the request start time in milliseconds.  `time` is a
function to measure machine time.

`method` determines whether the request should try to read the body of
the response.

Returns a map with the information about the HTTP response, including
its headers, and a body stream.

## `parse-url`
Function signature:

```
(parse-url url)
```

Parses a `url` string as URL.

Returns a table with `scheme`, `host`, `port`, `userinfo`, `path`,
`query`, and `fragment` fields from the URL.  If the `scheme` part of
the `url` is missing, the default `http` scheme is used.  If the
`port` part of the `url` is missing, the default port is used based on
the `scheme` part: `80` for the `http` and `443` for `https`.

## `read-headers`
Function signature:

```
(read-headers src ?headers)
```

Read and parse HTTP headers from `src`.
The optional parameter `?headers` is used for tail recursion, and
should not be provided by the caller, unless the intention is to
append or override existing headers.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
