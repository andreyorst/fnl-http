# Server.fnl

**Table of contents**

- [`start`](#start)

## `start`
Function signature:

```
(start handler conn)
```

Starts the server running the `handler` for each request.  Accepts
optional `conn` table, containing `host` and `port` for the server.

The `handler` is a function of one argument that receives the parsed
HTTP request. The return value of this function will be sent to the
client as a response.  Two formats of return values are supported:

1. `handler` can return the response body directly or throw it with
   the `error` function. In such cases, the response status is either
   `200` or `500`. If the response is a string, the content-length
   header field is calculated automatically. The response may also be
   a `reader`, an async.fnl channel or a file handle.

2. `handler` can return a table, containing the `status` field, and
   optional `headers`, `reason-phrase`, and `body` fields. The `body`
   field can contain the same kinds of values as above.

Note, the files and readers are automatically closed when the
connection to the client is closed. Readers also automatically close
when exhausted.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
