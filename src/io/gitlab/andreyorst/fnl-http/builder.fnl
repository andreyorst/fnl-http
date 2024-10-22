(local HTTP-VERSION "HTTP/1.1")

(local {: capitalize-header}
  (require :io.gitlab.andreyorst.fnl-http.headers))

(local {: format
        : upper}
  string)

(local {: concat
        : sort}
  table)

(fn header->string [header value]
  "Converts `header` and `value` arguments into a valid HTTP header string."
  {:private true}
  (.. (capitalize-header header) ": " (tostring value) "\r\n"))

(fn sort-headers [h1 h2]
  {:private true}
  (< (h1:match "^[^:]+") (h2:match "^[^:]+")))

(fn headers->string [headers]
  "Converts a `headers` table into a multiline string of HTTP headers."
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (header->string header value))
        (doto (sort sort-headers))
        concat)))

(fn build-http-request [method request-target ?headers ?content]
  "Formaths the HTTP request string as per the HTTP/1.1 spec.
`method` is a string, specifying the HTTP method.  `request-target` is
a path taken from the URL.  Optional `?headers` and `?content` provide
a headers table and a content string respectively."
  (format
   "%s %s %s\r\n%s\r\n%s"
   (upper method)
   request-target
   HTTP-VERSION
   (or (headers->string ?headers) "")
   (or ?content "")))

(fn build-http-response [status reason ?headers ?content]
  "Formats the HTTP response string as per the HTTP/1.1 spec.
`status` is a numeric code of the response.  `reason` is a string,
describing the response.  Optional `?headers` and `?content` provide a
headers table and a content string respectively."
  (format
   "%s %s %s\r\n%s\r\n%s"
   HTTP-VERSION
   (tostring status)
   reason
   (or (headers->string ?headers) "")
   (or ?content "")))

{: build-http-response
 : build-http-request
 : headers->string}
