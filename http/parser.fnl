(local {: make-reader
        : string-reader}
  (require :http.readers))

(local {: decode}
  (require :http.json))

(local {: decode-value
        : capitalize-header}
    (require :http.headers))

(fn parse-header [line]
  "Parse a single header from a `line`."
  (case (line:match " *([^:]+) *: *(.*)")
    (header value) (values header value)))

(fn read-headers [src ?headers]
  "Read and parse HTTP headers.
The optional parameter `?headers` is used for tail recursion, and
should not be provided by the caller, unless the intention is to
append or override existing headers."
  (let [headers (or ?headers {})
        line (src:read :*l)]
    (case line
      (where (or "\r" ""))
      headers
      _ (read-headers
         src
         (case (parse-header (or line ""))
           (header value)
           (doto headers (tset header value)))))))

;;; HTTP Response

(fn parse-response-status-line [status]
  "Parse HTTP response status line."
  (if status
      ((fn loop [reader fields res]
         (case fields
           [field & fields]
           (let [part (reader)]
             (loop reader fields
                   (case field
                     :protocol-version
                     (let [(name major minor) (part:match "([^/]+)/(%d).(%d)")]
                       (doto res
                         (tset field {: name :major (tonumber major) :minor (tonumber minor)})))
                     _ (doto res
                         (tset field (decode-value part))))
                   ))
           _
           (let [reason (-> "%s/%s.%s +%s +"
                            (string.format res.protocol-version.name res.protocol-version.major res.protocol-version.minor res.status)
                            (status:gsub ""))]
             (doto res
               (tset :reason-phrase reason)))))
       (status:gmatch "([^ ]+)")
       [:protocol-version :status]
       {})
      (error "status line was not received from server")))

(fn read-response-status-line [src]
  "Read the first line from the HTTP response and parse it."
  (parse-response-status-line (src:read :*l)))

(fn body-reader [src]
  "Read the body of the request, with possible buffering via the `peek`
method."
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
                        (set buffer (string.sub buffer (+ len 1)))
                        (if read-more?
                            (if buffer-content
                                (.. buffer-content (or (src:read (- n len)) ""))
                                (src:read (- n len)))
                            buffer-content))
                      (where (or :*l :l))
                      (let [read-more? (not (buffer:find "\n"))]
                        (when buffer-content
                          (set buffer (string.sub buffer (+ (length buffer-content) 2))))
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
                      _ (error (tostring pattern)))))
    :read-line (fn [src]
                 (let [rdr (string-reader buffer)
                       buffer-content (rdr:read :*l)
                       read-more? (not (buffer:find "\n"))]
                   (when buffer-content
                     (set buffer (string.sub buffer (+ (length buffer-content) 2))))
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
  ;; TODO: needs to process chunk extensions
  (case (src:read :*l)
    "" (read-chunk-size src)
    line
    (case (line:match "%s*([0-9a-fA-F]+)")
      size (tonumber (.. "0x" size))
      _ (error (string.format "line missing chunk size: %q" line)))))

(fn chunked-body-reader [src initial-chunk]
  "Reads body in chunks, buffering each fully, and requesting the next
chunk, once the buffer is empty."
  ;; TODO: think about rewriting it so the chunk is not required to be
  ;;       read in full.  The main problem with this approach is the
  ;;       possible chunk size - if the server sends a chunk large
  ;;       enough it can fill the memory, even if the user requested a
  ;;       stream.
  (var chunk-size initial-chunk)
  (var buffer (or (src:read chunk-size) ""))
  (var more? true)
  (fn read-more []
    ;; TODO: needs to process entity headers after the last chunk.
    (when more?
      (set chunk-size (read-chunk-size src))
      (if (> chunk-size 0)
          (set buffer (.. buffer (or (src:read chunk-size) "")))
          (set more? false)))
    (values (> chunk-size 0) (string-reader buffer)))
  (make-reader
   src
   {:read-bytes (fn [_ pattern]
                  (let [rdr (string-reader buffer)]
                    (case pattern
                      (where n (= :number (type n)))
                      (let [buffer-content (rdr:read pattern)
                            len (if buffer-content (length buffer-content) 0)
                            read-more? (< len n)]
                        (set buffer (string.sub buffer (+ len 1)))
                        (if read-more?
                            (let [(_ rdr) (read-more)]
                              (if buffer-content
                                  (.. buffer-content (or (rdr:read (- n len)) ""))
                                  (rdr:read (- n len))))
                            buffer-content))
                      (where (or :*l :l))
                      (let [buffer-content (rdr:read :*l)
                            (_ read-more?) (not (buffer:find "\n"))]
                        (when buffer-content
                          (set buffer (string.sub buffer (+ (length buffer-content) 2))))
                        (if read-more?
                            (let [rdr (read-more)]
                              (if buffer-content
                                  (.. buffer-content (or (rdr:read :*l) ""))
                                  (rdr:read :*l)))
                            buffer-content))
                      (where (or :*a :a))
                      (let [buffer-content (rdr:read :*a)]
                        (set buffer "")
                        (while (read-more) nil)
                        (let [rdr (string-reader buffer)]
                          (set buffer "")
                          (case (rdr:read :*a)
                            nil (when buffer-content
                                  buffer-content)
                            data (.. (or buffer-content "") data))))
                      _ (error (tostring pattern)))))
    :read-line (fn [src]
                 (let [rdr (string-reader buffer)
                       buffer-content (rdr:read :*l)
                       read-more? (not (buffer:find "\n"))]
                   (when buffer-content
                     (set buffer (string.sub buffer (+ (length buffer-content) 2))))
                   (if read-more?
                       (if buffer-content
                           (.. buffer-content (or (src:read :*l) ""))
                           (src:read :*l))
                       buffer-content)))
    :close (fn [src] (src:close))
    :peek (fn [_ bytes]
            (assert (= :number (type bytes)) "expected number of bytes to peek")
            (let [rdr (string-reader buffer)
                  content (or (rdr:read bytes) "")
                  len (length content)]
              (if (= bytes len)
                  content
                  (let [(_ rdr) (read-more)]
                    (let [data (rdr:read (- bytes len))]
                      (set buffer (.. buffer (or data "")))
                      buffer)))))}))

(local non-error-statuses
  {200 true
   201 true
   202 true
   203 true
   204 true
   205 true
   206 true
   207 true
   300 true
   301 true
   302 true
   303 true
   304 true
   307 true})

(fn parse-http-response [src {: as : parse-headers? : start : time : throw-errors?}]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `read`
method.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-response-status-line src)
        headers (read-headers src)
        parsed-headers (collect [k v (pairs headers)]
                         (capitalize-header k) (decode-value v))
        chunk-size (case (string.lower (or parsed-headers.Transfer-Encoding ""))
                     (where header (or (header:match "chunked[, ]")
                                       (header:match "chunked$")))
                     (read-chunk-size src))
        stream (if chunk-size
                   (chunked-body-reader src chunk-size)
                   (body-reader src))
        response (doto status
                   (tset :headers (if parse-headers?
                                      parsed-headers
                                      headers))
                   (tset :length (tonumber parsed-headers.Content-Length))
                   (tset :http-client src)
                   (tset :request-time
                         (when (and start time)
                           (math.ceil (* 1000 (- (time) start)))))
                   (tset :body
                         (case as
                           :raw (stream:read (or parsed-headers.Content-Length :*a))
                           :json (decode stream)
                           :stream stream
                           _ (error (string.format "unsupported coersion method '%s'" as)))))]
    (if (and throw-errors?
             (not (. non-error-statuses response.status)))
        (error response)
        response)))

;;; HTTP Request

(fn parse-request-status-line [status]
  "Parse HTTP request status line."
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (doto res
                 (tset field (decode-value part)))))
       _ res))
   (status:gmatch "([^ ]+)")
   [:method :path :http-version]
   {}))

(fn read-request-status-line [src]
  "Read the first line from the HTTP response and parse it."
  (parse-request-status-line (src:read :*l)))

(fn parse-http-request [src]
  (let [status (read-request-status-line src)
        headers (read-headers src)]
    (doto status
      (tset :headers headers)
      (tset :content (src:read :*a)))))

;;; URL

(fn parse-authority [authority]
  "Parse the `authority` part of a URL."
  (let [userinfo (authority:match "([^@]+)@")
        port (authority:match ":(%d+)")
        host (if userinfo
                 (authority:match (.. "@([^:]+)" (if port ":" "")))
                 (authority:match (.. "([^:]+)" (if port ":" ""))))]
    {: userinfo : port : host}))

(fn parse-url [url]
  "Parses a `url` string as URL.
Returns a table with `scheme`, `host`, `port`, `userinfo`, `path`,
`query`, and `fragment` fields from the URL.  If the `scheme` part of
the `url` is missing, the default `http` scheme is used.  If the
`port` part of the `url` is missing, the default port is used based on
the `scheme` part: `80` for the `http` and `443` for `https`."
  (let [scheme (url:match "^([^:]+)://")
        {: host : port : userinfo}
        (parse-authority
         (if scheme
             (url:match "//([^/]+)/?")
             (url:match "^([^/]+)/?")))
        scheme (or scheme "http")
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+(/[^?#]*)")
        query (url:match "%?([^#]+)#?")
        fragment (url:match "#([^?]+)%??")]
    {: scheme : host : port : userinfo : path : query : fragment}))

{: parse-http-response
 : parse-http-request
 : parse-url}
