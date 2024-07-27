(local HTTP-VERSION "HTTP/1.1")

(local {: capitalize-header}
  (require :http.headers))

(fn -header->string [header value]
  "Converts `header` and `value` arguments into a valid HTTP header
string."
  (.. (capitalize-header header) ": " (tostring value) "\r\n"))

(fn headers->string [headers]
  "Converts a `headers` table into a multiline string of HTTP headers."
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (-header->string header value))
        table.concat)))

(fn build-http-request [method request-target ?headers ?content]
  "Formaths the HTTP request string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   (string.upper method)
   request-target
   HTTP-VERSION
   (or (headers->string ?headers) "")
   (or ?content "")))

(fn build-http-response [status reason ?headers ?content]
  "Formats the HTTP response string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   HTTP-VERSION
   (tostring status)
   reason
   (or (headers->string ?headers) "")
   (or ?content "")))

{: build-http-response
 : build-http-request
 : headers->string}
