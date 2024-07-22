(local HTTP-VERSION "HTTP/1.1")

(local {: chan?}
  (require :lib.async))

(local utils
  (require :http.utils))

(local {: reader?}
  (require :http.readers))

(fn header->string [header value]
  "Converts `header` and `value` arguments into a valid HTTP header
string."
  (.. (utils.capitalize-header header) ": " (tostring value) "\r\n"))

(fn headers->string [headers]
  "Converts a `headers` table into a multiline string of HTTP headers."
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (header->string header value))
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

(fn encode-chunk [data]
  (let [len (length data)]
    (if (> len 0)
        (string.format "%x\r\n%s\r\n" len data)
        (string.format "%x\r\n\r\n" len))))

(fn prepare-chunk [body read-fn]
  (if (chan? body)
      (case (read-fn body)
        data (values true (encode-chunk data))
        nil (values false (encode-chunk "")))
      (reader? body)
      (case (body:read 1024)
        data (values true (encode-chunk data))
        nil (values false (encode-chunk "")))
      (error (.. "unsupported body type: " (type body)))))

(fn prepare-amount [body read-fn amount]
  (if (reader? body)
      (body:read amount)
      (error (.. "unsupported body type: " (type body)))))

{: build-http-response
 : encode-chunk
 : prepare-chunk
 : prepare-amount
 : build-http-request}