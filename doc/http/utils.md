# Utils.fnl

**Table of contents**

- `<!?`
- `>!?`
- [`chunked-encoding?`](#chunked-encoding)
- [`make-tcp-client`](#make-tcp-client)

## `<!?`
Function signature:

```
(<!? port)
```

Takes a value from `port`.  Will return `nil` if closed.  Will block
if nothing is available and used on the main thread.  Will park if
nothing is available and used in the `go` block.

## `>!?`
Function signature:

```
(>!? port val)
```

Puts a `val` into `port`.  `nil` values are not allowed.  Must be
called inside a `(go ...)` block.  Will park if no buffer space is
available.  Returns `true` unless `port` is already closed.

## `chunked-encoding?`
Function signature:

```
(chunked-encoding? transfer-encoding)
```

Test if `transfer-encoding` header is chunked.

## `make-tcp-client`
Function signature:

```
(make-tcp-client socket-channel resources)
```

Accepts a `socket-channel`. Wraps it with a bunch of
methods to act like Luasocket client. `resources` is a hash-set of
values mapped to `true` needed to be closed before the client is
closed.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
