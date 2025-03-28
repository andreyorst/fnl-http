(local {: decode-value
        : capitalize-header}
  (require :io.gitlab.andreyorst.fnl-http.impl.headers))

(local {: chunked-encoding?
        : multipart?
        : multipart-separator}
  (require :io.gitlab.andreyorst.fnl-http.impl.utils))

(local {: body-reader
        : chunked-body-reader
        : multipart-body-iterator}
  (require :io.gitlab.andreyorst.fnl-http.impl.body))

(local {: format : upper} string)

(local {: ceil} math)

(fn parse-header [line]
  "Parse a single header from a `line`."
  {:private true}
  (case (line:match " *([^:]+) *: *(.*)")
    (header value) (values header value)))

(fn read-headers [src ?headers]
  "Read and parse HTTP headers from `src`.
The optional parameter `?headers` is used for tail recursion, and
should not be provided by the caller, unless the intention is to
append or override existing headers."
  (let [headers (or ?headers {})]
    (case (src:read :*l)
      (where (or "\r" "" "\r\n" "\n")) headers
      ?line (read-headers
             src
             (case (parse-header (or ?line ""))
               (header value)
               (doto headers (tset header value)))))))

(fn parse-http-version [line]
  "Parse HTTP version from `line`."
  {:private true}
  (let [(name major minor) (line:match "([^/]+)/(%d).(%d)")]
    {: name :major (tonumber major) :minor (tonumber minor)}))

;;; HTTP Response

(fn parse-response-status-line [status]
  "Parse HTTP response status line."
  {:private true}
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (case field
                 :protocol-version
                 (doto res
                   (tset field (parse-http-version part)))
                 _
                 (doto res
                   (tset field (decode-value part))))))
       _
       (let [reason (-> "%s/%s.%s +%s +"
                        (format res.protocol-version.name
                                res.protocol-version.major
                                res.protocol-version.minor res.status)
                        (status:gsub ""))]
         (doto res
           (tset :reason-phrase reason)))))
   (status:gmatch "([^ ]+)")
   [:protocol-version :status]
   {}))

(fn read-response-status-line [src]
  "Read the first line from the HTTP response and parse it."
  {:private true}
  (case (src:read :*l)
    line (parse-response-status-line line)
    _ (error "status line was not received from server")))

(fn read-multipart-response [src separator]
  "Read multipart body from `src` until the last `separator` is met.
We have to read byte by byte because luasocket's `receive` method
doesn't include line feed or carriage return characters in the
returned string when using the `*l` pattern."
  {:private true}
  (let [end (.. "--" separator "--")]
    ((fn loop [data line]
       (let [byte (src:read 1)
             line (doto line (table.insert byte))]
         (case (when (= byte "\n")
                 (table.concat line))
           line (if (line:find end nil true)
                    (table.concat (doto data (table.insert line)))
                    (loop (doto data (table.insert line)) []))
           nil (loop data line))))
     [] [])))

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
              :raw (if (multipart? parsed-headers.Content-Type)
                       (read-multipart-response src (multipart-separator parsed-headers.Content-Type))
                       (stream:read (or parsed-headers.Content-Length :*a)))
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
  (case (src:read :*l)
    line (parse-request-status-line line)))

(fn encoding-type [headers method]
  "Determine request body encoding type via `headers` or `method` used."
  {:private true}
  (if (= (upper (or method "")) :HEAD) nil
      (multipart? headers.Content-Type) :multipart
      (chunked-encoding? headers.Transfer-Encoding) :chunked
      headers.Content-Length :stream))

(fn parse-http-request [src]
  "Parses the HTTP/1.1 request read from `src`.

If the request contained a body, it is returned as a `Reader` under
the `content` key.  Chunked encoding is supported by using a special
`chunked-body-reader`.

If the request had Content Type set to `multipart/*`, the `parts` key
is used, and contains an iterator function, that will iterate over
each part in the request.  Each part is a table with its respective
headers, anc a `content` key, containing a `Reader` object.

Each part's content must be processed or copied before moving to the
next part, as moving to the next part consumes the body data from
`src`.  Note, that when the part doesn't specify any content length or
chunked encoding ther content Reader is not limited to part's contents
and can read into the next part. If that's the case, parts have to be
dumped line by line and analyzed manually.

Returns a table with request `status`, `method`, `http-version`,
`headers` keys, including `content` or `parts` keys if payload was
provided, as described above."
  (let [status (read-request-status-line src)
        headers (read-headers src)
        parsed-headers (collect [k v (pairs headers)]
                         (capitalize-header k) (decode-value v))
        content (case (encoding-type parsed-headers status.method)
                  :multipart {:parts (multipart-body-iterator
                                      src
                                      (multipart-separator parsed-headers.Content-Type)
                                      read-headers)}
                  :stream {:content (body-reader src)}
                  :chunked {:content (chunked-body-reader src)}
                  _ {})]
    (when status.method
      (doto (collect [k v (pairs status) :into content] k v)
        (tset :headers headers)
        (tset :length parsed-headers.Content-Length)
        (tset :protocol-version (parse-http-version status.http-version))
        (tset :http-version nil)))))

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

{: parse-http-response
 : parse-http-request
 : parse-url
 : read-headers}
