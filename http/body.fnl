(local {: headers->string}
  (require :http.builder))

(local {: reader? : file-reader}
  (require :http.readers))

(local {: chan?}
  (require :lib.async))

(local {: <!?}
  (require :http.async-extras))

(fn get-chunk-data [body]
  (if (chan? body)
      (<!? body)
      (reader? body)
      (body:read 1024)
      (error (.. "unsupported body type: " (type body)))))

(fn format-chunk [body]
  (let [data? (get-chunk-data body)
        data (or data? "")]
    (values (not data?)
            (string.format "%x\r\n%s\r\n" (length data) data))))

(fn stream-chunks [dst body]
  "Writes chunks to `dst` obtained from the `body`.
Only used when the size of the individual chunks or a total content
lenght of the reader are not known.  The `body` can be a Channel or a
Reader.  In case of the `Reader`, it's being read in chunks of 1024
bytes."
  (let [(last-chunk? data) (format-chunk body)]
    (dst:write data)
    (when (not last-chunk?)
      (stream-chunks dst body))))

(fn stream-reader [dst body remaining]
  "Writes chunks read from `body` to `dst` until `remaining` reaches 0.
Used in cases when the reader was passed as the `body`, and the
Content-Length header was provided."
  (case (body:read (if (< 1024 remaining) 1024 remaining))
    data
    (do (dst:write data)
        (when (> remaining 0)
          (stream-reader
           dst body
           (- remaining (length data)))))))

(fn stream-channel [dst body remaining]
  "Writes chunks read from `body` to `dst` until `remaining` reaches 0.
Used in cases when the channel was passed as the multipart `body`, and the
Content-Length header was provided."
  (case (<!? body)
    data
    (let [data (if (< (length data) remaining) data (string.sub data 1 remaining))
          remaining (- remaining (length data))]
      (dst:write data)
      (when (> remaining 0)
        (stream-channel dst body remaining)))))

(fn stream-body [dst body {: transfer-encoding : content-length}]
  "Stream the given `body` to `dst`.
Depending on values of the headers and the type of the `body`, decides
how to stream the data."
  (when body
    (if (= transfer-encoding "chunked")
        (stream-chunks dst body)
        (and content-length (reader? body))
        (stream-reader dst body content-length)
        (and content-length (chan? body))
        (stream-channel dst body content-length))))

(fn guess-content-type [body]
  "Guess the content type of the `body`.
By default, string bodies are transferred with text/plain;
charset=UTF-8.  Readers and channels use application/octet-stream."
(if (= (type body) :string)
    "text/plain; charset=UTF-8"
      (or (chan? body)
          (reader? body))
      "application/octet-stream"
      (error (.. "Unsupported body type" (type body)) 2)))

(fn guess-transfer-encoding [body]
  "Guess the content transfer encoding for the `body`.
Strings are trasferred using the 8bit encoding, readers and channels
use binary encoding."
  (if (= (type body) :string)
      "8bit"
      (or (chan? body)
          (reader? body))
      "binary"
      (error (.. "Unsupported body type" (type body)) 2)))

(fn wrap-body [body]
  (case (type body)
    :table (if (chan? body) body
               (reader? body) body
               body)
    :userdata (case (getmetatable body)
                {:__name "FILE*"}
                (file-reader body)
                _ body)
    _ body))

(fn format-multipart-part [{: name : part-name : filename
                            : content :length content-length
                            : mime-type} boundary]
  "Format a single multipart entry.
The part starts with the `boundary`, followed by headers, created from
`part-name` (if none given the `name` is used), optional `filename`
for files, `mime-type`, and `content-length` which is either
calculated from `content` or provided explicitly.

Default headers include `content-disposition`, `content-length`,
`content-type`, and `content-transfer-encoding`."
  (let [content (wrap-body content)]
    (string.format
     "--%s\r\n%s\r\n"
     boundary
     (headers->string
      {:content-disposition (string.format "form-data; name=%q%s" (or part-name name)
                                           (if filename
                                               (string.format "; filename=%q" filename)
                                               ""))
       :content-length (if (= :string (type content))
                           (length content)
                           (or content-length (content:length)))
       :content-type (or mime-type (guess-content-type content))
       :content-transfer-encoding (guess-transfer-encoding content)}))))

(fn multipart-content-length [multipart boundary]
  "Calculate the total length of `multipart` body.
Needs to know the `boundary`."
  (+ (accumulate [total 0
                  _ {:length content-length
                     : name : part-name
                     : content
                     &as part}
                  (ipairs multipart)]
       (let [content (wrap-body content)]
         (+ total
            (length (format-multipart-part part boundary))
            (if (= :string (type content)) (+ (length content) 2)
                (reader? content)
                (+ 2 (or (content:length)
                         content-length
                         (error (string.format "can't determine length for multipart content %q" (or name part-name)) 2)))
                (not= nil content-length)
                (+ content-length 2)
                (error (string.format "missing length field on non-string multipart content %q" (or name part-name)) 2)))))
     (length (string.format "--%s--\r\n" boundary))))

(fn stream-multipart [dst multipart boundary]
  "Write `multipart` entries to `dst` separated with `boundary`."
  (each [_ {: name : part-name : filename
            : content :length content-length
            : mime-type
            &as part}
         (ipairs multipart)]
    (assert (not= nil content) "Multipart content cannot be nil")
    (assert (or part-name name) "Multipart body must contain at least content and name or part-name")
    (let [content (wrap-body content)]
      (->> (if (= :string (type content)) content "")
           (.. (format-multipart-part part boundary))
           (dst:write))
      (when (not= :string (type content))
        (stream-body dst content {:content-length (or content-length (content:length))})))
    (dst:write "\r\n"))
  (dst:write (string.format "--%s--\r\n" boundary)))

{: stream-body
 : format-chunk
 : stream-multipart
 : multipart-content-length
 : wrap-body}
