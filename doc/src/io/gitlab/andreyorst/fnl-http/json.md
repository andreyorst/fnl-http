# Json.fnl

**Table of contents**

- [`decode`](#decode)
- [`encode`](#encode)

## `decode`
Function signature:

```
(decode data)
```

Accepts `data`, which can be either a `Reader` that supports `peek`,
and `read` methods, a string, or a file handle.  Parses the first
logical JSON value to a Lua value.

## `encode`
Function signature:

```
(encode val)
```

Encode a Lua value `val` as JSON.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
