# Client.fnl

**Table of contents**

- [`connect`](#connect)
- [`delete`](#delete)
- [`get`](#get)
- [`head`](#head)
- [`options`](#options)
- [`patch`](#patch)
- [`post`](#post)
- [`put`](#put)
- [`request`](#request)
- [`trace`](#trace)

## `connect`
Function signature:

```
(connect url opts on-response on-raise)
```

Makes a `CONNECT` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `delete`
Function signature:

```
(delete url opts on-response on-raise)
```

Makes a `DELETE` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `get`
Function signature:

```
(get url opts on-response on-raise)
```

Makes a `GET` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `head`
Function signature:

```
(head url opts on-response on-raise)
```

Makes a `HEAD` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `options`
Function signature:

```
(options url opts on-response on-raise)
```

Makes a `OPTIONS` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `patch`
Function signature:

```
(patch url opts on-response on-raise)
```

Makes a `PATCH` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `post`
Function signature:

```
(post url opts on-response on-raise)
```

Makes a `POST` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `put`
Function signature:

```
(put url opts on-response on-raise)
```

Makes a `PUT` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `request`
Function signature:

```
(request method url opts on-response on-raise)
```

Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.

## `trace`
Function signature:

```
(trace url opts on-response on-raise)
```

Makes a `TRACE` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
"content-length" key. For a string body, if the "content-length"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
