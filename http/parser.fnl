(local {: make-reader
        : string-reader}
  (require :http.readers))

(local {: decode-value
        : capitalize-header}
  (require :http.headers))

(local {: <!?}
  (require :http.async-extras))

(local {: timeout}
  (require :lib.async))

(local {: format : lower : upper} string)

(local {: ceil} math)

(fn parse-header [line]
  "Parse a single header from a `line`."
  {:private true}
  (case (line:match " *([^:]+) *: *(.*)")
    (header value) (values header value)))

(fn read-headers [src ?headers]
  "Read and parse HTTP headers.
The optional parameter `?headers` is used for tail recursion, and
should not be provided by the caller, unless the intention is to
append or override existing headers."
  {:private true}
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
  {:private true}
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
                            (format res.protocol-version.name res.protocol-version.major res.protocol-version.minor res.status)
                            (status:gsub ""))]
             (doto res
               (tset :reason-phrase reason)))))
       (status:gmatch "([^ ]+)")
       [:protocol-version :status]
       {})
      (error "status line was not received from server")))

(fn read-response-status-line [src]
  "Read the first line from the HTTP response and parse it."
  {:private true}
  (parse-response-status-line (src:read :*l)))

(fn body-reader [src]
  "Read the body of the request, with possible buffering via the `peek`
method."
  {:private true}
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
                          (set buffer (buffer:sub (+ (length buffer-content) 2))))
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
  ;; TODO: needs to process chunk extensions
  (case (src:read :*l)
    "" (read-chunk-size src)
    line
    (case (line:match "%s*([0-9a-fA-F]+)")
      size (tonumber (.. "0x" size))
      _ (error (format "line missing chunk size: %q" line)))
    _ (error "source was exchausted while reading chunk size")))

(fn chunked-body-reader [src]
  "Reads body in chunks, buffering each fully, and requesting the next
chunk, once the buffer is empty."
  {:private true}
  ;; TODO: think about rewriting it so the chunk is not required to be
  ;;       read in full.  The main problem with this approach is the
  ;;       possible chunk size - if the server sends a chunk large
  ;;       enough it can fill the memory, even if the user requested a
  ;;       stream.
  (var buffer "")
  (var chunk-size nil)
  (var more? true)
  (var read-in-progress? false)
  (fn read-more []
    ;; TODO: needs to process entity headers after the last chunk.
    (while read-in-progress?
      (<!? (timeout 10)))
    (when more?
      (set read-in-progress? true)
      (set chunk-size (read-chunk-size src))
      (if (> chunk-size 0)
          (set buffer (.. buffer (or (src:read chunk-size) "")))
          (set more? false))
      (set read-in-progress? false))
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
                        (set buffer (or (rdr:read :*a) ""))
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
                          (set buffer (or (rdr:read :*a) "")))
                        (if read-more?
                            (let [(_ rdr) (read-more)]
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
                     (set buffer (or (rdr:read :*a) "")))
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

(fn chunked-encoding? [transfer-encoding]
  "Test if `transfer-encoding` header is chunked."
  (case (lower (or transfer-encoding ""))
    (where header (or (header:match "chunked[, ]")
                      (header:match "chunked$")))
    true))

(fn parse-http-response [src {: as : start : time : method}]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `read`
method.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

`as` is a string, describing how to coerse the response body.  It can
be one of `\"raw\"`, `\"stream\"`, or `\"json\"`.

`start` is the request start time in milliseconds.  `time` is a
function to measure machine time.

`method` determines whether the request should try to read the body of
the response.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-response-status-line src)
        headers (read-headers src)
        parsed-headers (collect [k v (pairs headers)]
                         (capitalize-header k) (decode-value v))
        stream (if (chunked-encoding? parsed-headers.Transfer-Encoding)
                   (chunked-body-reader src)
                   (body-reader src))]
    (doto status
      (tset :headers headers)
      (tset :parsed-headers parsed-headers)
      (tset :length (tonumber parsed-headers.Content-Length))
      (tset :http-client src)
      (tset :request-time
            (when (and start time)
              (ceil (* 1000 (- (time) start)))))
      (tset :body
            (when (not= (upper (or method "")) :HEAD)
              (case as
                :raw (stream:read (or parsed-headers.Content-Length :*a))
                (where (or :json :stream)) stream
                _ (error (format "unsupported coersion method '%s'" as))))))))

;;; HTTP Request

(fn parse-request-status-line [status]
  "Parse HTTP request status line."
  {:private true}
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
  {:private true}
  (parse-request-status-line (src:read :*l)))

(fn parse-http-request [src]
  "Parses the HTTP/1.1 request read from `src`."
  (let [status (read-request-status-line src)
        headers (read-headers src)]
    (doto status
      (tset :headers headers)
      (tset :content (src:read :*a)))))

;;; URL

(fn parse-authority [authority]
  "Parse the `authority` part of a URL."
  {:private true}
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
        [scheme url] (if scheme [scheme url]
                         ["http" (.. "http://" url)])
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+(/[^?#]*)")
        query (url:match "%?([^#]+)#?")
        fragment (url:match "#([^?]+)%??")]
    {: scheme : host : port : userinfo : path : query : fragment}))

{: parse-http-response : parse-http-request : chunked-encoding? : parse-url}
