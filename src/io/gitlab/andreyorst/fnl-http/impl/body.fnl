(local {: decode : encode}
  (require :io.gitlab.andreyorst.json))

(local {: reader? : file-reader : string-reader : make-reader}
  (require :io.gitlab.andreyorst.reader))

(local {: headers->string}
  (require :io.gitlab.andreyorst.fnl-http.impl.builder))

(local {: urlencode}
  (require :io.gitlab.andreyorst.fnl-http.impl.url))

(local {: chan? : timeout}
  (require :io.gitlab.andreyorst.async))

(local {: <!? : chunked-encoding?}
  (require :io.gitlab.andreyorst.fnl-http.impl.utils))

(local {: decode-value
        : capitalize-header}
  (require :io.gitlab.andreyorst.fnl-http.impl.headers))


(local {: format : lower}
  string)

(local {:type io/type}
  io)

(local {: min : floor}
  math)

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
             (chunked-encoding? transfer-encoding))
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

(fn wrap-body [body content-type]
  "Wraps `body` in a streamable object.
If the `content-type` is given and is `application/json` and the
`body` is a table it is encoded as JSON reader."
  (case (or (io/type body) (type body))
    :table (if (or (chan? body)
                   (reader? body))
               body
               (= :application/json (lower (or content-type "")))
               (string-reader (encode body))
               :else
               (tostring table))
    (where (or :file "closed file")) (file-reader body)
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
  (let [content (wrap-body content mime-type)
        headers (collect [k v (pairs (or headers {}))
                          :into {:content-disposition (format "form-data; name=%q%s%s" name
                                                              (if filename
                                                                  (format "; filename=%q" filename)
                                                                  "")
                                                              (if filename*
                                                                  (format "; filename*=%s" (urlencode filename*))
                                                                  ""))
                                 :content-length (if (= :string (type content))
                                                     (length content)
                                                     content-length)
                                 :content-type (or mime-type (guess-content-type content))
                                 :content-transfer-encoding (guess-transfer-encoding content)}]
                  k v)]

    (->> (doto headers
           (tset :transfer-encoding (when (= nil headers.content-length) "chunked")))
         headers->string
         (format "--%s\r\n%s\r\n" boundary))))

(fn multipart-content-length [multipart boundary]
  "Calculate the total length of `multipart` body.
Needs to know the `boundary`."
  (case (accumulate [total 0
                  _ {:length content-length
                     : content
                     &as part}
                  (ipairs multipart)
                  :until (= total nil)]
       (let [content (wrap-body content multipart.mime-type)]
         (when (or (= :string (type content))
                   content-length)
           (+ total
              (length (format-multipart-part part boundary))
              (if (= :string (type content)) (+ (length content) 2)
                  (not= nil content-length)
                  (+ content-length 2))))))
    parts-len (+ parts-len (length (format "--%s--\r\n" boundary)))))

(fn stream-multipart [dst multipart boundary]
  "Write `multipart` entries to `dst` separated with the `boundary`."
  (each [_ {: name
            : content :length content-length
            &as part}
         (ipairs multipart)]
    (assert (not= nil content) "Multipart content cannot be nil")
    (assert name "Multipart body must contain at least content and name")
    (let [content (wrap-body content multipart.mime-type)]
      (->> (if (= :string (type content)) content "")
           (.. (format-multipart-part part boundary))
           (dst:write))
      (when (not= :string (type content))
        (stream-body dst content {:content-length content-length
                                  :transfer-encoding (when (= nil content-length) "chunked")})))
    (dst:write "\r\n"))
  (dst:write (format "--%s--\r\n" boundary)))

(fn body-reader [src]
  "Read the body part of the request source `src`, with possible
buffering via the `peek` method."
  (var buffer "")
  (make-reader
   src
   {:read-bytes (fn [src pattern]
                  (let [rdr (string-reader buffer)
                        buffer-content (rdr:read pattern)]
                    (case pattern
                      (where n (= :number (type n)))
                      (let [len (if buffer-content (length buffer-content) 0)
                            read-more? (< len n)]
                        (set buffer (buffer:sub (+ len 1)))
                        (if read-more?
                            (if buffer-content
                                (.. buffer-content (or (src:read (- n len)) ""))
                                (src:read (- n len)))
                            buffer-content))
                      (where (or :*l :l))
                      (let [read-more? (not (buffer:find "\n"))]
                        (when buffer-content
                          (set buffer (buffer:sub (length buffer-content))))
                        (if read-more?
                            (if buffer-content
                                (.. buffer-content (or (src:read pattern) ""))
                                (src:read pattern))
                            buffer-content))
                      (where (or :*a :a))
                      (do (set buffer "")
                          (case (src:read pattern)
                            nil (when buffer-content
                                  buffer-content)
                            data (.. (or buffer-content "") data)))
                      _ (error (.. "unsupported pattern: " (tostring pattern))))))
    :read-line (fn [src]
                 (let [rdr (string-reader buffer)
                       buffer-content (rdr:read :*l)
                       read-more? (not (buffer:find "\n"))]
                   (when buffer-content
                     (set buffer (buffer:sub (+ (length buffer-content) 2))))
                   (if read-more?
                       (if buffer-content
                           (.. buffer-content (or (src:read :*l) ""))
                           (src:read :*l))
                       buffer-content)))
    :close (fn [src] (src:close))
    :peek (fn [src bytes]
            (assert (= :number (type bytes)) "expected number of bytes to peek")
            (let [rdr (string-reader buffer)
                  content (or (rdr:read bytes) "")
                  len (length content)]
              (if (= bytes len)
                  content
                  (let [data (src:read (- bytes len))]
                    (set buffer (.. buffer (or data "")))
                    buffer))))}))

(fn read-chunk-size [src]
  {:private true}
  ;; TODO: do something with chunk extensions
  (case (src:read :*l)
    (where (or "" "\r"))
    (read-chunk-size src)
    line
    (case (line:match "%s*([0-9a-fA-F]+)")
      size (tonumber size 16)
      _ (error (format "line missing chunk size: %s" line)))
    _ (error "source was exchausted while reading chunk size")))

(fn chunked-body-reader [src]
  "Reads the body part of the request source `src` in chunks, buffering
each in full, and requesting the next chunk, once the buffer contains
less data than was requested."
  ;; TODO: Rewrite so the chunk is not required to be read in full.
  ;;       The main problem with this approach is the possible chunk
  ;;       size - if the server sends a chunk large enough it can fill
  ;;       the memory, even if the user requested a stream.
  (var buffer "")
  (var chunk-size nil)
  (var more? true)
  (var read-in-progress? false)
  (fn read-next-chunk []
    (while read-in-progress?
      (<!? (timeout 10)))
    (when more?
      (set read-in-progress? true)
      (set chunk-size (read-chunk-size src))
      (if (> chunk-size 0)
          (set buffer (.. buffer (or (src:read chunk-size) "")))
          ((fn read-entity-headers [line]
             ;; TODO: needs to actually process entity headers
             (case line
               (where (or "" "\r")) (set more? false)
               _ (read-entity-headers (src:read :*l))))))
      (set read-in-progress? false))
    (values (> chunk-size 0) (string-reader buffer)))
  (fn read-bytes [_ pattern]
    (let [number? (= :number (type pattern))
          rdr (string-reader buffer)]
      (case (values pattern number?)
        (where (or :*l :l (_ true)))
        (let [read-more?
              (if number?
                  (< (length buffer) pattern)
                  (buffer:find "\n" nil true))]
          (if read-more?
              (case (read-next-chunk)
                true (read-bytes _ pattern)
                (false rdr)
                (let [content (rdr:read pattern)]
                  (set buffer (or (rdr:read :*a) ""))
                  content))
              (let [content (rdr:read pattern)]
                (set buffer (or (rdr:read :*a) ""))
                content)))
        (where (or :*a :a))
        (do (while (read-next-chunk) nil)
            (let [rdr (string-reader buffer)]
              (set buffer "")
              (rdr:read :*a)))
        _ (error (.. "unsupported pattern: " (tostring pattern))))))
  (fn read-line [src]
    (let [rdr (string-reader buffer)
          has-newline? (buffer:find "\n" nil true)]
      (if has-newline?
          (case (read-next-chunk)
            true (read-line src)
            (false rdr)
            (let [content (rdr:read :*l)]
              (set buffer (or (rdr:read :*a) ""))
              content))
          (let [content (rdr:read :*l)]
            (set buffer (or (rdr:read :*a) ""))
            content))))
  (fn peek [_ bytes]
    (assert (= :number (type bytes)) "expected number of bytes to peek")
    (let [rdr (string-reader buffer)]
      (if (< (length buffer) bytes)
          (case (read-next-chunk)
            true (peek _ bytes)
            (false rdr) (rdr:peek bytes))
          (rdr:peek bytes))))
  (fn close [src]
    (src:close))
  (make-reader src {: read-bytes : peek : read-line : close}))

(fn sized-body-reader [reader bytes]
  "Wraps existing `reader` limiting amount of data that will be read to
`bytes`."
  (assert (reader? reader) "expected a reader as the first argument")
  (assert (and (= :number (type bytes))
               (= bytes (floor bytes)))
          "expected an integer as the second argument")
  (var left bytes)
  (let [lines (reader:lines)]
    (make-reader nil {:read-bytes (fn [_ bytes]
                                    (when (> left 0)
                                      (case bytes
                                        (where bytes (= :number (type bytes)))
                                        (let [data (reader:read (min bytes left))]
                                          (set left (- left (length data)))
                                          data)
                                        (where (or :a :*a))
                                        (let [data (reader:read left)]
                                          (set left 0)
                                          data)
                                        _ (let [data (reader:read bytes)]
                                            (set left (- left (length data)))
                                            data))))
                      :peek (fn [_ bytes]
                              (when (> left 0)
                                (reader:peek (min bytes left))))
                      :read-line (fn [_]
                                   (when (> left 0)
                                     (case (lines reader)
                                       line (do (set left (- left (length line)))
                                                line))))
                      :close reader.close})))

(fn multipart-body-iterator [src separator read-headers]
  "Accepts `src`, part `separator` and a `read-headers` function,
building an iterator over multipart request parts.  Each part's
headers are parsed with `read-headers` function.  Returns an iterator,
that in turn returns parts as tables with `headers` table, `type` of
the attachment, `name` and/or `filename` fields, and a `content`
field.  The `content` field is always a `Reader`, and must be
processed before advancing the iterator.  Otherwise, the reader will
be exhausted by the iterator, as it advances to the next part
`separator`.  Once the final separator is met, iterator returns `nil`."
  (var exhausted nil)
  (let [separator (.. "--" separator)]
    (fn _next [_ _]
      (when (not exhausted)
        (var found nil)
        (while (not found)
          (let [line (or (src:read :*l) "")]
            (case (line:find separator 0 true)
              (_ end)
              (do (set found true)
                  (set exhausted (line:find "--" end true))))))
        (when (and (not exhausted) found)
          (let [headers (read-headers src)
                parsed-headers (collect [k v (pairs headers)]
                                 (capitalize-header k) (decode-value v))
                disposition (or parsed-headers.Content-Disposition "")
                (attachment-type attachment-params) (disposition:match "([^;]+); *(.*)")]
            (collect [k v (attachment-params:gmatch "([^= ]+)= *([^;]+)")
                      :into {:headers headers
                             :length parsed-headers.Content-Length
                             :type attachment-type
                             :content (do
                                        (var closed? false)
                                        (make-reader
                                         (if (chunked-encoding? parsed-headers.Transfer-Encoding)
                                             (chunked-body-reader src)
                                             parsed-headers.Content-Length
                                             (-> src
                                                 body-reader
                                                 (sized-body-reader parsed-headers.Content-Length))
                                             ;; TODO: maybe implement a reader in terms of a buffer
                                             ;;       to read the data only relying on part separators
                                             (body-reader src))
                                         {:read-bytes (fn [rdr pattern]
                                                        (when (not closed?)
                                                          (rdr:read pattern)))
                                          :read-line (fn [rdr _]
                                                       (when (not closed?)
                                                         (rdr:read :*l)))
                                          :peek (fn [rdr bytes]
                                                  (when (not closed?)
                                                    (rdr:read bytes)))
                                          :close (fn [_] (set closed? true))}))}]
              k (case (pcall decode v) (true v) v _ v))))))))

{: stream-body
 : format-chunk
 : stream-multipart
 : multipart-content-length
 : wrap-body
 : body-reader
 : chunked-body-reader
 : multipart-body-iterator
 : sized-body-reader}
