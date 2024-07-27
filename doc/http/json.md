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
and `read` methods or a string.  Parses the contents to a Lua table.

## `encode`
Function signature:

```
(encode val)
```

Encode a Lua value `val` as JSON.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
