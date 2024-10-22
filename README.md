# fnl-http

A [clj-http][1]-inspired library for making HTTP/1.1 requests written in Fennel.
This library utilizes [async.fnl][2] for asynchronous request processing and [luasocket][3] for an actual implementation of sockets.

# Installation

1. Clone the repo:
   ```
   $ git clone https://gitlab.com/andreyorst/fnl-http
   ```
2. Invoke `fennel tasks/install --prefix TARGET-DIR` at the root of the repository.
   The `TARGET-DIR` is a directory where you wish to install the library:
   ```
   $ fennel tasks/install --prefix /path/to/your/project/libs
   ```
3. Make sure that `TARGET-DIR` from the previous step is in your fennel PATH:
   ```
   $ cd /path/to/your/project
   $ fennel --add-package-path './libs/?.lua --repl
   ```
4. Require the library:
   ```fennel
   >> (local http (require :io.gitlab.andreyorst.fnl-http))
   nil
   ```

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

A generic function `client.request` accepts the method name as a string and is a base for all other functions internally.

All functions accept the `opts` table, which contains the following keys:

- `async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.
  The successful response of a server is then passed to the `on-response` callback.
  In case of any error during the request, the `on-raise` callback is called with the error message.
- `headers` - a table with the HTTP headers for the request
- `body` - an optional string body.
- `as` - how to coerce the body of the response.
- `throw-errors?` - whether to throw errors on response statuses other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302, 303, 304, 307.
  Defaults to `true`.
- `multipart` - a list of multipart parts.
  See [multipart examples](#multipart-form-data) below.

Several options are available for the `as` key:

- `stream` - the body will be a stream object with a `read` method.
- `raw` - the body will be a string.
  This is the default value for `as`.
- `json` - the body will be parsed as JSON into a Lua table.
  Note, that `null` values are omitted from the resulting table.

## Examples

Loading the library:

```fennel
(local http (require :io.gitlab.andreyorst.fnl-http))
```

The library provides three main modules:

- `http.client`, containing all of the HTTP methods and a generic `request` function,
- `http.readers`, containing [readers](#readers)
- `http.json`, containing a [json parser and encoder](#json-support)

All other modules are preloaded and for internal use only.

The `http` module also contains all HTTP method functions, so it can be used as `http.get` instead of `http.client.get`.
If preferred, modules can be imported as separate locals with destructuring:

```fennel
(local {: client : readers : json}
  (require :io.gitlab.andreyorst.fnl-http))
```

### Accessing resources synchronously

The default scheme for requests is `http://` if not provided explicitly.
If the path part is missing, it defaults to `/`.
Here's an example of accessing `http://lua-users.org/`:

```fennel
(http.get "lua-users.org")
```

The response is a table, containing the headers, body, and additional info:

```fennel
{:body "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">..."
 :http-client #<SocketChannel: 0x55c220a1dcc0>
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

Each function accepts a table with options, that can modify how the request is made, or how the response is provided.
For example, if the body is larger, it can be processed as a stream, by supplying the following options table:

```fennel
(http.get "http://lua-users.org/" {:as :stream})
```

In the response table, the `body` key will contain a `#<Reader: 0x55c220e65920>` object.

```fennel
{:body #<Reader: 0x55c220e65920>
 :http-client #<SocketChannel: 0x55c221568ba0>
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

Beware, that before closing the `http-client`, you must consume the body of the response.

### Accessing resources asynchronously

By supplying an options table with the `async?` key set to `true`, the request will be processed asynchronously:

```fennel
(http.get "http://lua-users.org/" {:async? true} on-response on-raise)
```

The result will be a channel, which can be awaited using the `async` library, but it's not required:

```fennel
#<ManyToManyChannel: 0x55c221b267c0>
```

The channel itself, however, won't contain the response.
Instead, it has to be processed with the `on-response` and `on-raise` callbacks.
The `on-response` and `on-raise` callback run in the asynchronous context, thus blocking operations should be avoided.

```fennel
(http.get "http://lua-users.org/"
          {:async? true
           :as :stream
           :headers {:connection "close"}}
          (fn on-response [resp]
            (print (resp.body:read :*a)))
          (fn on-raise [err]
            (case err
              {: status : reason-phrase}
              (io.stderr:write status " " reason-phrase "\n")
              _ (io.stderr:write err "\n"))))
```

In its default form, this library doesn't require you to use `async.fnl` directly.
However, by using the `async.fnl` library, more options are available.
For example, multiple requests can be issued, selecting the fastest:

```fennel
(let [index (http.get "http://lua-users.org/"
                      {:async? true
                       :as :stream
                       :headers {:connection :close}}
                      on-response on-raise)
      wiki (http.get "http://lua-users.org/wiki/"
                     {:async? true
                      :as :stream
                      :headers {:connection :close}}
                     on-response on-raise)]
  (go (match (alts! [index wiki])
        [_ index] (print "lua-users.org/ was faster")
        [_ wiki] (print "lua-users.org/wiki/ was faster"))))
```

Refer to the [documentation][4] for more on how to use the `async.fnl` library.

### `multipart/form-data`

You can send multipart requests with the `multipart` field in the `opts` table:

```fennel
(http.post "http://example.com"
           {:multipart
            [{:name "text" :content "text data"}
             {:name "channel"
              :content some-channel
              :length 322}
             {:name "text-stream"
              :content (http.readers.string-reader "some text")}
             {:name "file"
              :content (io.open "pic.png")
              :filename "pic.png"
              :mime-type "image/png"}]})
```

Additional fields can be added to each part:

- `name` - part name.
- `filename` - optional file name
- `filename*` - optional file name with ASCII-only characters.
  The client automatically URL-encodes this field as per [rfc5987][5].
- `content` - the body of the part.
  Can be a string, a Reader, a file, or a channel.
- `length` - optional content length.
  Must be specified if there's no way to determine length from the content object.
- `headers` - additional headers for the given part.
- `mime-type` - optional mime type for the given part.
  By default, the mime type is guessed based on the `content` field.

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
- `lines` - returns a function, that returns lines, similar to `(: (io.open "file") :lines)`
- `close` - closes the Reader, such that all methods no longer return any values.

Readers help process large request bodies and allow stream-like workflow.

There are a few predefined readers:

- `file-reader` - wraps a file handle, or a path string, and returns a Reader.
- `string-reader` - wraps a string, returning a Reader.
- `ltn12-reader` - wraps an LTN12 source, returning a Reader <sup><i>yo dawg we put a reader on your reader, so you could read while you read</i></sup>.

Custom Reader objects can be created with the `make-reader` function.
This function accepts the object to read from, and a table of methods:

- `read-bytes` - should read a specified amount of bytes, and advance the object in some way.
- `read-line` - should return a single line, and advance the object.
- `peek` - should read a specified amount of bytes, without advancing a reader.
- `close` - should close the object, such that other functions will no longer use it, and return `nil` on any call.

All methods are optional, and nonexistent methods will return `nil` by default.
Provide a method that throws an error, if you want your Reader to prohibit some methods.

### Server

This library contains a proof-of-concept HTTP/1.1 server.
It's a simple asynchronous server, that accepts a handler function doing all of the heavy-lifting of routing, and provides a simple API for the response format.

Here's an example handler implementation:

```fennel
(fn handler [{: path : headers &as request}]
  (case path
    "/" (let [url (.. "http://" headers.Host "/index.html")
              body (.. "<!DOCTYPE HTML>"
                       "<title>Redirecting...</title><h1>Redirecting...</h1>"
                       "<p>You should be redirected automatically to target URL: "
                       "<a href=\"" url "\">" url "</a>.  If not click the link.</p>")]
          {:status 302
           :headers {:connection "close"
                     :location "/index.html"
                     :content-length (length body)}
           :body body})
    _ (case (io.open (.. "." path))
        file {:status 200
              :headers {:connection (or headers.Connection :keep-alive)
                        :transfer-encoding :chunked
                        :content-type (case (path:match "%.(.-)$")
                                        :html :text/html
                                        :ico :image/x-icon
                                        _ :application/octet-stream)}
              :body file}
        _ (let [body "404: not found"]
            {:status 404
             :headers {:connection (or headers.Connection "keep-alive")
                       :content-length (length body)
                       :content-type "text/plain"}
             :body body}))))
```

This handler doesn't handle request methods other than `GET` and serves all files in the server's working directory.
The server can then be ran like this:

```fennel
(local {: server} (require :io.gitlab.andreyorst.fnl-http))
(local handler (require :handler))

(local server
  (server.start-server handler {:port 12345}))

(server:wait)
```

The `(server:wait)` call blocks the main thread.
If the application has some kind of main loop, the server would run by itself and no call to the `wait` method would be needed.

The server is experimental and not properly tested.

[1]: https://github.com/dakrone/clj-http
[2]: https://gitlab.com/andreyorst/async.fnl
[3]: https://w3.impa.br/~diego/software/luasocket/home.html
[4]: https://gitlab.com/andreyorst/async.fnl/-/blob/main/doc/src/async.md
[5]: https://www.rfc-editor.org/rfc/rfc5987
