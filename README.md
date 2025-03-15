# fnl-http

A [clj-http][1]-inspired library for making HTTP/1.1 requests written in Fennel.
This library utilizes [async.fnl][2] for asynchronous request processing and [luasocket][3] for an actual implementation of sockets.

## Installation via [deps.fnl](https://gitlab.com/andreyorst/deps.fnl)

Add the following to `deps.fnl` file:

```fennel
{:deps {"https://gitlab.com/andreyorst/fnl-http"
        {:type :git :sha "1db56eb1736ad5366f6811aacf1ffa450f94c08f"}}}
```

## Usage

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

### Examples

Loading the library:

```fennel
(local http (require :io.gitlab.andreyorst.fnl-http))
```

The library provides four main modules:

- `http.client`, containing all of the HTTP methods and a generic `request` function,
- `http.readers`, containing [readers](#extra-modules)
- `http.json`, containing a [json parser and encoder](#extra-modules)
- `http.server`, containing a [server implementation](#http-server)

All other modules are preloaded and for internal use only.

The `http` module also contains all HTTP method functions, so it can be used as `http.get` instead of `http.client.get`.
If preferred, modules can be imported as separate locals with destructuring:

```fennel
(local {: client : readers : json}
  (require :io.gitlab.andreyorst.fnl-http))
```

#### Accessing resources synchronously

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

#### Accessing resources asynchronously

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

#### `multipart/form-data`

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

### Extra modules

The main client module provides two more modules for convenience:

```fennel
(local json http.json) ;; JSON parser and encoder
(local readers http.readers) ;; Reader module for creating readers
```

Refer to each projects documentation for each module:

- [json.fnl](https://gitlab.com/andreyorst/json.fnl/-/blob/main/doc/src/json.md)
- [reader.fnl](https://gitlab.com/andreyorst/reader.fnl/-/blob/main/doc/src/reader.md)

#### HTTP Server

This library contains a simple HTTP/1.1 server.
The module provides a single function that accepts an asynchronous handler doing all of the heavy lifting of routing and provides a simple data-oriented API for the response format.
The handler runs in the implicit asynchronous context, thus blocking code should be avoided.
If `async.fnl` functions are used inside the handler, all code must use parking operations on channels.

The server can then be started like this:

```fennel
(server.start handler-fn connection)
```

The returned object is a server with the following methods:

- `stop` - stops the server.
- `close` - same as `stop`.
- `wait` - blocks the main thread, waiting for the server to finish.

Additionally, the object provides the following fields:

- `server` - underlying luasocket TCP server object.
- `host` - server's host
- `port` - server's port

By default, the server is automatically running in the background via the `async.fnl` event loop.
If the application has some kind of main loop, the call to the `wait` is not required.
Otherwise, if the sole purpose of the application is to serve requests, the `wait` method can be used to force the event loop to run.

The response is either a table, with the following format:

```fennel
{:status 200
 :headers {}         ; optional
 :reason-phrase "OK" ; optional
 :body "pong"        ; optional
 }
```

The body key value can be a string, channel, reader, or file handle.

The server is experimental and not properly tested.

##### Working with requests

Each incoming request is passed to the `handler` function as a table:

```fennel
{:headers {:Host "localhost:3000"}
 :http-version "HTTP/1.1"
 :method "GET"
 :path "/"}
```

For methods that provide payload, this table will contain either the `content` key or the `parts` key.

The `content` key is always a Reader.
It should always be consumed by the handler, even if the contents are not used by the underlying code.

The `parts` key appears when the request content type is specified as `multipart/*`, and is always an iterator function.
Each time the `parts` function is called the next part is returned.

A part is represented as the following table:

```fennel
{:content #<Reader: 0x558d30ffe4b0>
 :filename "qux"
 :headers {:Content-Disposition "form-data; name=\"baz\"; filename=\"qux\""
           :Content-Length "3"
           :Content-Transfer-Encoding "8bit"
           :Content-Type "text/plain; charset=UTF-8"}
 :name "baz"
 :type "form-data"}
```

The `content` key is a Reader.
It must be processed before accessing the next part.
If it is not used before accessing the next part, it will be exhausted once the next part is fetched.
Thus all parts can't be obtained in advance without losing data.

Here's an example of working with multipart requests:

```fennel
(fn handler [request]
  (case request
    {: parts}
    (each [part parts]
      (process-part part))))
```

##### Server Performance

Using the following server implementation:

```fennel
(local async (require :io.gitlab.andreyorst.async))
(local server (require :io.gitlab.andreyorst.fnl-http.server))

(fn handler [{: headers &as request}]
  (async.<! (async.timeout 50))
  {:status 200
   :headers {:connection (or headers.Connection "keep-alive")
             :content-length 11
             :content-type "text/plain"}
   :body "hello world"})

(local s (server.start handler {:port 3000}))
(s:wait)
```

Testing with the [wrk][6] tool with the following command `wrk -t12 -c400 -d30s http://localhost:3000` yields about 2k requests per second:

```
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   146.42ms   94.13ms   2.00s    98.54%
    Req/Sec   205.07     90.83   343.00     62.36%
  69835 requests in 30.09s, 8.00MB read
  Socket errors: connect 0, read 0, write 0, timeout 151
Requests/sec:   2321.21
Transfer/sec:    272.37KB
```

Testing with [ab][7] with the following command `ab -k -t 30 -c 12 http://localhost:3000/` yields vastly different results:

```
Concurrency Level:      12
Time taken for tests:   30.043 seconds
Complete requests:      2985
Failed requests:        0
Keep-Alive requests:    2985
Total transferred:      358200 bytes
HTML transferred:       32835 bytes
Requests per second:    99.36 [#/sec] (mean)
Time per request:       120.774 [ms] (mean)
Time per request:       10.064 [ms] (mean, across all concurrent requests)
Transfer rate:          11.64 [Kbytes/sec] received
```

Such benchmarks are largely synthetic and may not represent the actual performance.

[1]: https://github.com/dakrone/clj-http
[2]: https://gitlab.com/andreyorst/async.fnl
[3]: https://w3.impa.br/~diego/software/luasocket/home.html
[4]: https://gitlab.com/andreyorst/async.fnl/-/blob/main/doc/src/async.md
[5]: https://www.rfc-editor.org/rfc/rfc5987
[6]: https://github.com/wg/wrk
[7]: https://httpd.apache.org/docs/2.4/programs/ab.html
