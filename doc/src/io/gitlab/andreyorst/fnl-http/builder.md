# Builder.fnl

**Table of contents**

- [`build-http-request`](#build-http-request)
- [`build-http-response`](#build-http-response)
- [`headers->string`](#headers-string)

## `build-http-request`
Function signature:

```
(build-http-request method request-target ?headers ?content)
```

Formaths the HTTP request string as per the HTTP/1.1 spec.
`method` is a string, specifying the HTTP method.  `request-target` is
a path taken from the URL.  Optional `?headers` and `?content` provide
a headers table and a content string respectively.

## `build-http-response`
Function signature:

```
(build-http-response status reason ?headers ?content)
```

Formats the HTTP response string as per the HTTP/1.1 spec.
`status` is a numeric code of the response.  `reason` is a string,
describing the response.  Optional `?headers` and `?content` provide a
headers table and a content string respectively.

## `headers->string`
Function signature:

```
(headers->string headers)
```

Converts a `headers` table into a multiline string of HTTP headers.


<!-- Generated with Fenneldoc v1.0.1
     https://gitlab.com/andreyorst/fenneldoc -->
