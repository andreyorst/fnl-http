# Headers.fnl

**Table of contents**

- [`capitalize-header`](#capitalize-header)
- [`decode-value`](#decode-value)
- [`get-boundary`](#get-boundary)

## `capitalize-header`
Function signature:

```
(capitalize-header header)
```

Capitalizes the `header` string.

## `decode-value`
Function signature:

```
(decode-value value)
```

Tries to coerce a `value` to a number, `true, or `false`.
If coersion fails, returns the value as is.

## `get-boundary`
Function signature:

```
(get-boundary headers)
```

Get boundary `fragment` from the `content-type` header.
Accepts the `headers` table.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
