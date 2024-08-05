(local {: headers->string}
  (require :http.builder))

(local {: reader? : file-reader}
  (require :http.readers))

(local {: chunked-encoding?}
  (require :http.parser))

(local {: urlencode}
  (require :http.url))

(local {: chan?}
  (require :lib.async))

(local {: <!?}
  (require :http.async-extras))

(local format string.format)

(fn get-chunk-data [src]
  "Obtain a single chunk from `src`."
  {:private true}
  (if (chan? src)
      (<!? src)
      (reader? src)
      (src:read 1024)
      (error (.. "unsupported source type: " (type src)))))

(fn format-chunk [src]
  "Formats a part of the `src` as a chunk with a calculated size."
  (let [data? (get-chunk-data src)
        data (or data? "")]
    (values (not data?)
            (format "%x\r\n%s\r\n" (length data) data))))

(fn stream-chunks [dst src]
  "Writes chunks to `dst` obtained from the `src`.
Only used when the size of the individual chunks or a total content
lenght of the reader are not known.  The `src` can be a Channel or a
Reader.  In case of the `Reader`, it's being read in chunks of 1024
bytes."
  {:private true}
  (let [(last-chunk? data) (format-chunk src)]
    (dst:write data)
    (when (not last-chunk?)
      (stream-chunks dst src))))

(fn stream-reader [dst src remaining]
  "Writes chunks read from `src` to `dst` until `remaining` reaches 0.
Used in cases when the reader was passed as the `src`, and the
Content-Length header was provided."
  {:private true}
  (case (src:read (if (< 1024 remaining) 1024 remaining))
    data
    (do (dst:write data)
        (when (> remaining 0)
          (stream-reader
           dst src
           (- remaining (length data)))))))

(fn stream-channel [dst src remaining]
  "Writes chunks read from `src` to `dst` until `remaining` reaches 0.
Used in cases when the channel was passed as the multipart `src`, and
the Content-Length header was provided."
  {:private true}
  (case (<!? src)
    data
    (let [data (if (< (length data) remaining) data (data:sub 1 remaining))
          remaining (- remaining (length data))]
      (dst:write data)
      (when (> remaining 0)
        (stream-channel dst src remaining)))))

(fn stream-body [dst body {: transfer-encoding : content-length}]
  "Stream the given `body` to `dst`.
Depending on values of the headers and the type of the `body`, decides
how to stream the data. Streaming from channels and readers requires
the `content-length` field to be present. If the `transfer-encoding`
field specifies a chunked encoding, the body is streamed in chunks."
  (when body
    (if (and (= :string (type transfer-encoding))
             (chunked-encoding? transfer-encoding)
             (or (transfer-encoding:match "chunked[, ]")
                 (transfer-encoding:match "chunked$")))
        (stream-chunks dst body)
        (and content-length (reader? body))
        (stream-reader dst body content-length)
        (and content-length (chan? body))
        (stream-channel dst body content-length))))

(fn guess-content-type [body]
  "Guess the content type of the `body`.
By default, string bodies are transferred with text/plain;
charset=UTF-8.  Readers and channels use application/octet-stream."
  {:private true}
  (if (= (type body) :string)
      "text/plain; charset=UTF-8"
      (or (chan? body)
          (reader? body))
      :application/octet-stream
      (error (.. "Unsupported body type" (type body)) 2)))

(fn guess-transfer-encoding [body]
  "Guess the content transfer encoding for the `body`.
Strings are trasferred using the 8bit encoding, readers and channels
use binary encoding."
  {:private true}
  (if (= (type body) :string)
      :8bit
      (or (chan? body)
          (reader? body))
      :binary
      (error (.. "Unsupported body type" (type body)) 2)))

(fn wrap-body [body]
  "Wraps `body` in a streamable object."
  (case (type body)
    :table (if (chan? body) body
               (reader? body) body
               body)
    :userdata (case (getmetatable body)
                {:__name :FILE*}
                (file-reader body)
                _ body)
    _ body))

(fn format-multipart-part [{: name : filename : filename*
                            : content :length content-length
                            : headers
                            : mime-type} boundary]
  "Format a single multipart entry.
The part starts with the `boundary`, followed by headers, created from
`name`, optional `filename` or `filename*` for files, `mime-type`, and
`content-length` which is either calculated from `content` or provided
explicitly.

Default headers include `content-disposition`, `content-length`,
`content-type`, and `content-transfer-encoding`. Provide `headers` for
additional or to change the default ones."
  {:private true}
  (let [content (wrap-body content)]
    (format
     "--%s\r\n%s\r\n"
     boundary
     (headers->string
      (collect [k v (pairs (or headers {}))
                :into {:content-disposition (format "form-data; name=%q%s%s" name
                                                    (if filename
                                                        (format "; filename=%q" filename)
                                                        "")
                                                    (if filename*
                                                        (format "; filename*=%s" (urlencode filename*))
                                                        ""))
                       :content-length (if (= :string (type content))
                                           (length content)
                                           (or content-length (content:length)))
                       :content-type (or mime-type (guess-content-type content))
                       :content-transfer-encoding (guess-transfer-encoding content)}]
        k v)))))

(fn multipart-content-length [multipart boundary]
  "Calculate the total length of `multipart` body.
Needs to know the `boundary`."
  (+ (accumulate [total 0
                  _ {:length content-length
                     : name
                     : content
                     &as part}
                  (ipairs multipart)]
       (let [content (wrap-body content)]
         (+ total
            (length (format-multipart-part part boundary))
            (if (= :string (type content)) (+ (length content) 2)
                (reader? content)
                (+ 2 (or content-length
                         (content:length)
                         (error (format "can't determine length for multipart content %q" name) 2)))
                (not= nil content-length)
                (+ content-length 2)
                (error (format "missing length field on non-string multipart content %q" name) 2)))))
     (length (format "--%s--\r\n" boundary))))

(fn stream-multipart [dst multipart boundary]
  "Write `multipart` entries to `dst` separated with the `boundary`."
  (each [_ {: name : filename
            : content :length content-length
            : mime-type
            &as part}
         (ipairs multipart)]
    (assert (not= nil content) "Multipart content cannot be nil")
    (assert name "Multipart body must contain at least content and name")
    (let [content (wrap-body content)]
      (->> (if (= :string (type content)) content "")
           (.. (format-multipart-part part boundary))
           (dst:write))
      (when (not= :string (type content))
        (stream-body dst content {:content-length (or content-length (content:length))})))
    (dst:write "\r\n"))
  (dst:write (format "--%s--\r\n" boundary)))

{: stream-body
 : format-chunk
 : stream-multipart
 : multipart-content-length
 : wrap-body}
