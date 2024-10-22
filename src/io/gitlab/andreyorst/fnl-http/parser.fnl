(local {: make-reader
        : string-reader}
  (require :io.gitlab.andreyorst.fnl-http.readers))

(local {: decode-value
        : capitalize-header}
  (require :io.gitlab.andreyorst.fnl-http.headers))

(local {: <!? : chunked-encoding?}
  (require :io.gitlab.andreyorst.fnl-http.utils))

(local {: timeout}
  (require :io.gitlab.andreyorst.async))

(local {: body-reader : chunked-body-reader}
  (require :io.gitlab.andreyorst.fnl-http.body))

(local {: format : upper : lower} string)

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
  (let [headers (or ?headers {})]
    (case (src:read :*l)
      (where (or "\r" "")) headers
      ?line (read-headers
             src
             (case (parse-header (or ?line ""))
               (header value)
               (doto headers (tset header value)))))))

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
                 (let [(name major minor) (part:match "([^/]+)/(%d).(%d)")]
                   (doto res
                     (tset field {: name :major (tonumber major) :minor (tonumber minor)})))
                 _ (doto res
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
  (case (src:read :*l)
    line (parse-request-status-line line)))

(fn parse-http-request [src]
  "Parses the HTTP/1.1 request read from `src`."
  (let [status (read-request-status-line src)
        headers (read-headers src)
        parsed-headers (collect [k v (pairs headers)]
                         (capitalize-header k) (decode-value v))
        stream (if (chunked-encoding? parsed-headers.Transfer-Encoding)
                   (chunked-body-reader src)
                   (body-reader src))]
    (case status
      {: method}
      (doto status
        (tset :headers headers)
        (tset :content
            (when (not= (upper (or method "")) :HEAD)
              (if parsed-headers.Content-Length
                  (stream:read parsed-headers.Content-Length)
                  (or (= :close (lower (or parsed-headers.Connection "")))
                      (chunked-encoding? parsed-headers.Transfer-Encoding))
                  (stream:read :*a))))))))

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
 : parse-url}
