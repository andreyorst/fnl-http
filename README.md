# http.fnl

A [clj-http][1]-inspired library for making HTTP/1.1 requests written in Fennel.
This library utilizes [async.fnl][3] for asynchronous request processing and [luasocket][3] for an actual implementation of sockets.

# Building

To build a self-contained library to use in other projects, run the following command in the root of the repository:

    fennel tasks/build

This command produces a file named `http.lua` at the root directory of the repository, which is ready to be used.

# Usage

The `http.client` module provides the following functions:

- `get`
- `post`
- `put`
- `patch`
- `options`
- `trace`
- `head`
- `delete`
- `connect`

Each invokes a specified HTTP method.

A generic function `client.request` accepts method name as a string and is a base for all other functions internally.

All functions accepts the `opts` table, that contains the following keys:

- `async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.
  The successful response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is called with the error message.
- `headers` - a table with the HTTP headers for the request
- `body` - an optional string body.
- `as` - how to coerce the body of the response.
- `throw-errors?` - whether to throw errors on response statuses other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302, 303, 304, 307.
  Defaults to `true`.
- `multipart` - a list of multipart parts.
  See [multipart examples](#multipart) below.

Several options available for the `as` key:

- `stream` - the body will be a stream object with a `read` method.
- `raw` - the body will be a string.
  This is the default value for `as`.
- `json` - the body will be parsed as JSON into a Lua table.
  Note, `null` values are omitted from the resulting table.

## Examples

Loading the library.

```fennel
(local http (require :http))
```

### Accessing resources synchronously

```fennel
(http.get "http://lua-users.org/")
```

The response will be a table:

```fennel
{:body "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">..."
 :client #<SocketChannel: 0x55c220a1dcc0>
 :headers {:Accept-Ranges "bytes"
           :Connection "keep-alive"
           :Content-Length "1055"
           :Content-Type "text/html"
           :Date "Fri, 19 Jul 2024 13:46:58 GMT"
           :ETag "\"61acad05-41f\""
           :Last-Modified "Sun, 05 Dec 2021 12:13:57 GMT"
           :Server "nginx/1.20.1"
           :Strict-Transport-Security "max-age=0;"}
 :length 1055
 :protocol-version {:major 1 :minor 1 :name "HTTP"}
 :reason-phrase "OK"
 :request-time 60
 :status 200}
```

The body can be processes as a stream, by supplying an options table:

```fennel
(http.get "http://lua-users.org/" {:as :stream})
```

In the response table, the `body` key will contain a `#<Reader: 0x55c220e65920>` object.

```fennel
{:body #<Reader: 0x55c220e65920>
 :client #<SocketChannel: 0x55c221568ba0>
 :headers {:Accept-Ranges "bytes"
           :Connection "keep-alive"
           :Content-Length "1055"
           :Content-Type "text/html"
           :Date "Fri, 19 Jul 2024 13:48:28 GMT"
           :ETag "\"61acad05-41f\""
           :Last-Modified "Sun, 05 Dec 2021 12:13:57 GMT"
           :Server "nginx/1.20.1"
           :Strict-Transport-Security "max-age=0;"}
 :length 1055
 :protocol-version {:major 1 :minor 1 :name "HTTP"}
 :reason-phrase "OK"
 :request-time 59
 :status 200}
```

Beware, that before closing the `client`, you must consume the body of the response.

### Accessing resources asynchronously

By supplying an options table with the `async?` key set to `true`, the request will be processed asynchronously.

```fennel
(http.get "http://lua-users.org/" {:async? true} on-response on-raise)
```

The result will be a channel, which can be awaited using the `async` library:

```fennel
#<ManyToManyChannel: 0x55c221b267c0>
```

The channel itself won't contain the response.
Instead, it has to be interacted with the `on-response` and `on-raise` callbacks.
The `on-response` and `on-raise` callback run in the asynchronous context, thus blocking operations should be avoided.

```fennel
(<!! (http.get "http://lua-users.org/"
               {:async? true
                :as :stream}
               (fn on-response [resp]
                 (print (resp.body:read resp.length)))
               (fn on-raise [err-resp]
                 (io.stderr:write (err-resp.body:read resp.length)))))

```

By using the `async.fnl` library, multiple requests can be issued, selecting the fastest:

```fennel
(go
  (let [on-response (fn [resp]
                      (print (resp.body:read :*a)))
        on-raise (fn [err-resp]
                   (io.stderr:write err-resp.status))]
    (async.alts! [(http.get "http://lua-users.org/"
                            {:async? true
                             :headers {:connection :close}}
                            on-response on-raise)
                  (http.get "http://lua-users.org/wiki/"
                            {:async? true
                             :headers {:connection :close}}
                            on-response on-raise)])))
```

Refer to the `async.fnl` documentation for more.

### Multipart

You can send multipart requests with the `multipart` field in the `opts` table:

```fennel
(http.post "http://example.com"
           {:multipart
            [{:name "text" :content "text data"}
             {:name "channel" :content some-channel}
             {:name "text-stream"
              :content (http.readers.string-reader "some text")}
             {:name "file"
              :content (http.readers.file-reader "pic.png")
              :filename "pic.png"
              :mime-subtype "image/png"}]})
```

## Extra modules

After loading the main client module, extra public modules are available:

```fennel
(local json http.json) ;; json parser and encoder
(local readers http.readers) ;; Reader module for creating readers
```

### JSON support

The `json` module contains two functions: `encode` and `decode`.

The `encode` function, produces a JSON string, given any Lua value, including tables.
**Note**, cyclic tables are not supported.

You can either use `json.encode` or just call the `json` module as a function:

```fennel
(json.encode {:foo "bar" :baz [1 2 3]})
;; "{\"baz\": [1, 2, 3], \"foo\": \"bar\"}"
```

The `decode` function, decodes a given string, or a Reader object:

```fennel
(json.decode "{\"baz\": [1, 2, 3], \"foo\": \"bar\"}")
;; {:baz [1 2 3] :foo "bar"}
(json.decode (readers.string-reader "{\"baz\": [1, 2, 3], \"foo\": \"bar\"}"))
;; {:baz [1 2 3] :foo "bar"}
```

### Readers

A Reader is a stateful object, which has a few specific methods:

- `read` - reads an amount of bytes (or a pattern) from the Reader, advancing it.
- `peek` - peeks at a specified amount of bytes without advancing the Reader.
- `lines` - returns a function, that returns lines, similarly to `(: (io.open "file") :lines)`
- `close` - closes the Reader, such that all methods no longer return any values.

Readers are helpful for processing large request bodies, allowing stream-like workflow.

There are a few predefined readers:

- `file-reader` - wraps a file handle, or a path string, and returns a Reader.
- `string-reader` - wraps a string, returning a Reader.
- `ltn12-reader` - wraps an LTN12 source, returning a Reader <sup><i>yo dawg we put a reader on your reader, so you could read while you read</i></sup>.

You can create your own Reader objects with the `make-reader` function.
This function accepts the object to read from, and a table of methods:

- `read-bytes` - should read a specified amount of bytes, and advance the object in some way.
- `read-line` - should return a single line, and advance the object.
- `peek` - should read a specified amount of bytes, without advancing a reader.
- `close` - should close the object, such that other functions will no longer use it, and return `nil` on any call.

All methods are optional, and nonexistent methods will return `nil` by default.
Provide a method that throws an error, if you want your Reader to prohibit some methods.

[1]: https://github.com/dakrone/clj-http
[2]: https://gitlab.com/andreyorst/async.fnl
[3]: https://w3.impa.br/~diego/software/luasocket/home.html
