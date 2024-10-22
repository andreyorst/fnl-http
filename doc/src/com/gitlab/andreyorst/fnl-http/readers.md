# Readers.fnl

**Table of contents**

- [`file-reader`](#file-reader)
- [`ltn12-reader`](#ltn12-reader)
- [`make-reader`](#make-reader)
- [`reader?`](#reader)
- [`string-reader`](#string-reader)

## `file-reader`
Function signature:

```
(file-reader file)
```

Creates a `Reader` from the given `file`.
Accepts a file handle or a path string which is opened automatically.

## `ltn12-reader`
Function signature:

```
(ltn12-reader source step)
```

Creates a `Reader` from LTN12 `source`.
Accepts an optional `step` function, to pump data from source when
required.  If no `step` provided, the default `ltn12.pump.step` is
used.

## `make-reader`
Function signature:

```
(make-reader source {:close close :length length :peek peek :read-bytes read-bytes :read-line read-line})
```

Generic reader generator.
Accepts methods, that the `source` is going to be passed, and produce
appropriate results.

Available methods:

- `close` method should return `true` when the resource is first
closed, and `nil` for repeated attempts at closing the reader.
- `read-bytes` method should return a specified amount of bytes,
determined either by the number of bytes, or by a supported read
pattern.
- `read-line` method should return a logical line of text, if the
reader source supports line iteration.
- `peek` method should read a specified amount of bytes without moving
  the position in the reader.
- `length` method should return the amount of bytes left in the
  reader.

All methods are optional, and if not provided, the return value of
each is `nil`.

## `reader?`
Function signature:

```
(reader? obj)
```

Check if `obj` is an instance of `Reader`.

## `string-reader`
Function signature:

```
(string-reader string)
```

Creates a `Reader` from the given `string`.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
