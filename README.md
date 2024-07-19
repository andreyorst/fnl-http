# http.fnl (WIP)

A library for making asynchronous HTTP/1.1 requests written in Fennel using [async.fnl][1] and [luasocket][2]

# Building

To build a self-contained library to use in other projects, run the following command in the root of the repository:

    fennel tasks/build

This command produces a file named `http.lua` at the root directory of the repository, which is ready to be used.

# Usage

The `http` module provides the following functions:

- `http.get`
- `http.post`
- `http.put`
- `http.patch`
- `http.options`
- `http.trace`
- `http.head`
- `http.delete`
- `http.connect`

Each invokes a specified HTTP method.

A generic function `http.request` accepts method name as a string.

All functions accepts the `opts` table, that contains the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is an instance of a `promise-chan`, and the body must
  be read inside of a `go` block.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional string body.
- `:as` - how to coerce the body of the response.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON into a Lua table.
  Note, `null` values are omitted from the resulting table.

## Examples

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
(http.get "http://lua-users.org/" {:async? true})
```

The result will be a promise channel, which can be awaited using the `async` library:

```fennel
#<ManyToManyChannel: 0x55c221b267c0>
```

If the body is requested to be a `stream`, the body must be read in asynchronous context, for example in a `go` block:

```fennel
(go
 (let [resp (<! (http.get "http://lua-users.org/"
                          {:async? true
                           :as :stream}))]
   (resp.body:read :*l)))
```

By using the `async.fnl` library, multiple requests can be issued, selecting the fastest:

```fennel
(go
  (async.alts! [(http.get "http://lua-users.org/" {:async? true})
                (http.get "http://lua-users.org/wiki/" {:async? true})]))
```

Refer to the `async.fnl` documentation for more.

[1]: https://gitlab.com/andreyorst/async.fnl
[2]: https://w3.impa.br/~diego/software/luasocket/home.html
