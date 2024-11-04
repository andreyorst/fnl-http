# Json.fnl

**Table of contents**

- [`decode`](#decode)
- [`encode`](#encode)
- [`register-encoder`](#register-encoder)
- [`unregister-encoder`](#unregister-encoder)

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

## `register-encoder`
Function signature:

```
(register-encoder object object? object-encoder)
```

Add custom `object` encoder.

If there's a custom object that is not supported by JSON encoder, the
`object-encoder` function can be registered to it via the `object?`
checker.  The `object?` is a function that, given an `object`, will
return a unique identifier for that `object`.  The identifier must be
a singleton, to ensure its uniquess across different data types.

The `object-encoder` is a function of two arguments.  The first
argument is the `object` itself, and the second argument is the
`encode` function, that is passed automatically, and can be used to
encode nested values.

### Examples

For example, proxy objects have a problem that they usually wrap an
empty table with custom metatable that deals with data access.  The
JSON encoder can distinguish between objects and arrays based on
special hueristics, but given a proxy object it can break.

For example, let's create a zero-indexed array:

```fennel
(local Array [])

(fn zero-indexed-array [...]
  (let [vals [...]]
    (setmetatable
     Array
     {:__index (fn [_ i]
                 (. vals (+ i 1)))
      :__newindex (fn [i val]
                    (tset vals (- i 1) val))
      :__len #(length vals)
      :__pairs (fn [_] #(next vals $2))})))
```

Omitting the rest of metatable machinery, we now have a custom object
that behaves as an array.  However, encoding it as JSON yields an
incorrect result:

```fennel
(encode (zero-indexed-array 1 2 3))
"[2, 3, null]"
```

A custom encoder can be provided to fix that:

```fennel
(fn array? [x]
  (and (= x Array) Array))

(fn encode-array [arr encode]
  (.. "["
      (-> (fcollect [i 0 (- (length arr) 1)]
            (encode (. arr i)))
          (table.concat ", "))
      "]"))

(json.register-encoder (zero-indexed-array) array? encode-array)
```

Note that `encode-array` accepts `encode` function and calls it on
array elements:

```fennel
>> (json (zero-indexed-array 1 2 3))
"[1, 2, 3]"
```

This should provide enough flexibility to support arbitrary proxy
objects.

## `unregister-encoder`
Function signature:

```
(unregister-encoder object object?)
```

Remove an `object` encoder defined with `register-encoder`.
Uses `object?` to find encoder to remove.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
