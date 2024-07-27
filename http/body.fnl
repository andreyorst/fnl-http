(local {: headers->string}
  (require :http.builder))

(local {: reader?}
  (require :http.readers))

(local {: chan?}
  (require :lib.async))

(fn format-chunk [body read-fn]
  (let [data? (if (chan? body)
                  (read-fn body)
                  (reader? body)
                  (body:read 1024)
                  (error (.. "unsupported body type: " (type body))))
        data (or data? "")]
    (values (not data?)
            (string.format "%x\r\n%s\r\n" (length data) data))))

(fn stream-chunks [dst body send receive]
  "Sends chunks to `dst` obtained from the `body`.
Only used when the size of the individual chunks or a total content
lenght of the reader are not known.  The `body` can be a Channel or a
Reader.  If the `body` is a Channel, `receive` is used to get the
data.  In case of the `Reader`, it's being read in chunks of 1024
bytes.  The resulting data is then `send` to `dst`."
  (let [(last-chunk? data) (format-chunk body receive)]
    (send dst data)
    (when (not last-chunk?)
      (stream-chunks dst body send receive))))

(fn stream-reader [dst body send remaining]
  "Sends chunks read from `body` to `dst` until `remaining` reaches 0.
Used in cases when the reader was passed as the `body`, and the
Content-Length header was provided. Uses the `send` function to send
chunks to the `dst`."
  (let [data (body:read (if (< 1024 remaining) 1024 remaining))]
    (when data
      (send dst data)
      (when (> remaining 0)
        (stream-reader
         dst body send
         (- remaining (length data)))))))

(fn stream-channel [dst body send receive remaining]
  "Sends chunks read from `body` to `dst` until `remaining` reaches 0.
Used in cases when the channel was passed as the multipart `body`, and the
Content-Length header was provided. Uses the `send` function to send
chunks to the `dst`."
  (let [data (receive body)
        data (if (< (length data) remaining) data (string.sub data 1 remaining))
        remaining (- remaining (length data))]
    (send dst data)
    (when (> remaining 0)
      (stream-channel
       dst body send receive
       remaining))))

(fn stream-body [dst body send receive
                 {: transfer-encoding
                  : content-length}]
  "Stream the given `body` to `dst` using `send`.
Depending on values of the headers and the type of the `body`, decides
how to stream the data."
  (when body
    (if (= transfer-encoding "chunked")
        (stream-chunks dst body send receive)
        (and content-length (reader? body))
        (stream-reader dst body send content-length)
        (and content-length (chan? body))
        (stream-channel dst body send content-length))))

(fn guess-content-type [body]
  (if (= (type body) :string)
      "text/plain; charset=UTF-8"
      (or (chan? body)
          (reader? body))
      "application/octet-stream"
      (error (.. "Unsupported body type" (type body)) 2)))

(fn guess-transfer-encoding [body]
  (if (= (type body) :string)
      "8bit"
      (or (chan? body)
          (reader? body))
      "binary"
      (error (.. "Unsupported body type" (type body)) 2)))

(fn format-multipart [bodies boundary receive]
  (-> (icollect [_ {: name : part-name : content
                    : mime-type :length content-length
                    : filename}
                 (ipairs bodies)]
        (do (assert (not= nil content) "Multipart content cannot be nil")
            (assert (or part-name name) "Multipart body must contain at least content and name or part-name")
            (string.format
             "--%s\r\n%s\r\n%s"
             boundary
             (headers->string {:content-disposition (string.format "form-data; name=%q%s" (or part-name name)
                                                                   (if filename
                                                                       (string.format "; filename=%q" filename)
                                                                       ""))
                               :content-type (or mime-type (guess-content-type content))
                               :content-transfer-encoding (guess-transfer-encoding content)})
             (if (= :string (type content))
                 content
                 (reader? content)
                 (content:read :*a)
                 (chan? content)
                 ((fn loop [res data]
                    (if data
                        (loop (.. res (receive content)))
                        res))
                  "" (receive content))))))
      (table.concat "\r\n")
      (.. (string.format "\r\n--%s--\r\n" boundary))))

{: stream-body
 : format-chunk
 : format-multipart}
