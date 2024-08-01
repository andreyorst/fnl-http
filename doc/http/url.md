# Url.fnl

**Table of contents**

- [`format-path`](#format-path)
- [`parse-url`](#parse-url)
- [`urlencode`](#urlencode)

## `format-path`
Function signature:

```
(format-path {:fragment fragment :path path :query query} query-params)
```

Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL, and optional  `query-params` table.

## `parse-url`
Function signature:

```
(parse-url url)
```

Parses a `url` string as URL.
Returns a table with `scheme`, `host`, `port`, `userinfo`, `path`,
`query`, and `fragment` fields from the URL.  If the `scheme` part of
the `url` is missing, the default `http` scheme is used.  If the
`port` part of the `url` is missing, the default port is used based on
the `scheme` part: `80` for the `http` and `443` for `https`.  Calling
`tostring` on parsed URL returns a string representation, but doesn't
guarantee the same order of query parameters.

## `urlencode`
Function signature:

```
(urlencode str allowed-char-pattern)
```

Percent-encode string `str`.
Accepts optional `allowed-char-pattern` to override default allowed
characters. The default pattern is `"[^%w._~-]"`.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
