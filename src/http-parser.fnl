(local {: make-reader
        &as reader}
  (include :readers))

(local json
  (include :json))

(local utils
  (include :utils))

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
                     (tset field (utils.as-data part))))
               ))
       _
       (let [reason (-> "%s/%s.%s +%s +"
                        (string.format res.protocol-version.name res.protocol-version.major res.protocol-version.minor res.status)
                        (status:gsub ""))]
         (doto res
           (tset :reason-phrase reason)))))
   (status:gmatch "([^ ]+)")
   [:protocol-version :status]
   {}))

(fn read-response-status-line [src]
  "Read the first line from the HTTP response and parse it."
  (parse-response-status-line (src:read :*l)))

(fn body-reader [src]
  (var buffer "")
  (make-reader
   src
   {:read-bytes (fn [src pattern]
                  (let [rdr (reader.string-reader buffer)
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
                 (let [rdr (reader.string-reader buffer)
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
            (let [rdr (reader.string-reader buffer)
                  content (or (rdr:read bytes) "")
                  len (length content)]
              (if (= bytes len)
                  content
                  (let [data (src:read (- bytes len))]
                    (set buffer (.. buffer (or data "")))
                    buffer))))}))

(fn read-chunk-size [src]
  (case (src:read :*l)
    "" (read-chunk-size src)
    line
    (case (line:match "%s*([0-9a-fA-F]+)")
      size (tonumber (.. "0x" size))
      _ (error (string.format "line missing chunk size: %q" line)))))

(fn chunked-body-reader [src initial-chunk]
  (var chunk-size initial-chunk)
  (var buffer (or (src:read chunk-size) ""))
  (var more? true)
  (fn read-more []
    (when more?
      (set chunk-size (read-chunk-size src))
      (if (> chunk-size 0)
          (set buffer (.. buffer (or (src:read chunk-size) "")))
          (set more? false)))
    (values (> chunk-size 0) (reader.string-reader buffer)))
  (make-reader
   src
   {:read-bytes (fn [src pattern]
                  (let [rdr (reader.string-reader buffer)]
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
                          (let [rdr (reader.string-reader buffer)]
                            (set buffer "")
                            (case (rdr:read :*a)
                              nil (when buffer-content
                                    buffer-content)
                              data (.. (or buffer-content "") data))))
                      _ (error (tostring pattern)))))
    :read-line (fn [src]
                 (let [rdr (reader.string-reader buffer)
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
            (let [rdr (reader.string-reader buffer)
                  content (or (rdr:read bytes) "")
                  len (length content)]
              (if (= bytes len)
                  content
                  (let [(last? rdr) (read-more)]
                    (let [data (rdr:read (- bytes len))]
                      (set buffer (.. buffer (or data "")))
                      buffer)))))}))

(fn parse-http-response [src {: as : parse-headers? : start : time}]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `read`
method.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-response-status-line src)
        headers (read-headers src)
        parsed-headers (collect [k v (pairs headers)]
                         (utils.capitalize-header k) (utils.as-data v))
        chunk-size (case (string.lower (or parsed-headers.Transfer-Encoding ""))
                     "chunked" (read-chunk-size src))
        stream (if chunk-size
                   (chunked-body-reader src chunk-size)
                   (body-reader src))]
    (doto status
      (tset :headers (if parse-headers?
                         parsed-headers
                         headers))
      (tset :length (tonumber parsed-headers.Content-Length))
      (tset :client src)
      (tset :request-time
            (when (and start time)
              (math.ceil (* 1000 (- (time) start)))))
      (tset :body
            (case as
              :raw (stream:read (or parsed-headers.Content-Length :*a))
              :json (json.parse stream)
              :stream stream
              _ (error (string.format "unsupported coersion method '%s'" as)))))))

(comment
 (let [req (build-http-response 200 "OK" {:connection :close} "vaiv\ndaun\n")
       rdr (reader.string-reader req)
       {: body : headers : reason-phrase : status}
       (parse-http-response rdr (fn [src pattern] (src:read pattern)) {:as :raw})]
   (= req (build-http-response status reason-phrase headers body)))
 )

;;; HTTP Request

(fn parse-request-status-line [status]
  "Parse HTTP request status line."
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (doto res
                 (tset field (utils.as-data part)))))
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

(comment
 (let [req (build-http-request :get "/" {:connection :close} "vaiv\ndaun\n")
       rdr (reader.string-reader req)
       {: headers : method : path : content}
       (parse-http-request rdr (fn [src pattern] (src:read pattern)) rdr)]
   (= req (build-http-request method path headers content)))
 )

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
             (url:match "//([^/]+)/")
             (url:match "^([^/]+)/")))
        scheme (or scheme "http")
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+/([^?#]+)")
        query (url:match "%?([^#]+)#?")
        fragment (url:match "#([^?]+)%??")]
    {: scheme : host : port : userinfo : path : query : fragment}))

{: parse-http-response
 : parse-http-request
 : parse-url}
