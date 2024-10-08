# Parser.fnl

**Table of contents**

- [`parse-http-request`](#parse-http-request)
- [`parse-http-response`](#parse-http-response)
- [`parse-url`](#parse-url)

## `parse-http-request`
Function signature:

```
(parse-http-request src)
```

Parses the HTTP/1.1 request read from `src`.

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


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
