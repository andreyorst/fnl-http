(local socket
  (require :socket))
(local {: <! : >! : <!! : >!! : close!
        : chan : promise-chan : chan?
        : tcp}
  (require :async))
(import-macros
 {: go}
 (doto :async require))

;;; Helper functions

(fn capitalize-header [header]
  "Capitalizes the header string."
  (-> (icollect [word (header:gmatch "[^-]+")]
        (-> word
            string.lower
            (string.gsub "^%l" string.upper)))
      (table.concat "-")))

(fn header->string [header value]
  "Converts `header` and `value` arguments into a valid HTTP header
string."
  (.. (capitalize-header header) ": " (tostring value) "\r\n"))

(fn headers->string [headers]
  "Converts a `headers` table into a multiline string of HTTP headers."
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (header->string header value))
        table.concat)))

(fn try-tonumber [value]
  "Tries to coerce a `value` to a number.
If coersion fails, returns the value as is."
  (case (tonumber value) n n _ value))

(fn make-read-fn [pattern]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src]
    (src:receive pattern)))

;;; LTN12

(local ltn12 {})
(local (ltn12? ltn)
  (pcall require :ltn12))

(fn ltn12.source! [port]
  "Creates a LTN12-compatible asyncronous source from a channel `port`."
  (assert ltn12? "ltn12 module requires ltn12 from luasocket")
  (if (chan? port)
      (fn [] (<! port))
      (ltn.source.empty "expected a channel")))

(fn ltn12.sink! [port]
  "Creates a LTN12-compatible sink that asyncrhonously puts into the
channel `port`.  The channel is automatically closed when sink
receives a `nil` value."
  (assert ltn12? "ltn12 module requires ltn12 from luasocket")
  (if (chan? port)
      (fn [chunk]
        (if (= nil chunk)
            (close! port)
            (>! port chunk))
        1)
      (ltn.source.empty "expected a channel")))

(fn ltn12.sink->chan [sink buffer-or-n xform err-handler]
  "Transforms the given `sink` into a channel with an optional buffer, an
optional transducer, and an optional error handler.  Rhis channel will
pump all of values coming into it into the given `sink`, stopping when
the channel is closed.  See the doc for the `chan` function to read
more about `buffer-or-n`, `xform` and `err-handler` arguments."
  (assert ltn12? "ltn12 module requires ltn12 from luasocket")
  (let [ch (chan buffer-or-n xform err-handler)]
    (go
      (-> ch
          ltn12.source!
          (ltn.pump.all sink)))
    ch))

(fn ltn12.source->chan [source step]
  "Transforms the `source` into a channel by pumping all values into a channel sink.
The channel is closed when source produces a `nil` value.

The `step` function is a LTN12 complient pump step function.  It
accepts a source and a sink as its arguments, calling souce first,
then calling sink with return values from source, unless it returned
an error.  Use this function to override default stepping behavior.

For example, luasocket sources can timeout, and thus pump will stop,
while the desired behavior may be to call `<!` on a `timeout` channel
and continue."
  (assert ltn12? "ltn12 module requires ltn12 from luasocket")
  (let [ch (chan)]
    (go (ltn.pump.all source (ltn12.sink! ch) step))
    ch))

;;; HTTP building

(local HTTP-VERSION "HTTP/1.1")

(fn make-http-request [method request-target ?headers ?content]
  "Formaths the HTTP request string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   (string.upper method)
   request-target
   HTTP-VERSION
   (or (headers->string ?headers) "")
   (or ?content "")))

(fn make-http-response [status reason ?headers ?content]
  "Formats the HTTP response string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   HTTP-VERSION
   (tostring status)
   reason
   (or (headers->string ?headers) "")
   (or ?content "")))

;;; HTTP parsing

(fn parse-status-line [status]
  "Parse HTTP response status line."
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (doto res
                 (tset field (try-tonumber part)))))
       _
       (let [reason (-> "%s +%s +"
                        (string.format res.http-version res.status)
                        (status:gsub ""))]
         (doto res
           (tset :reason reason)))))
   (status:gmatch "([^ ]+)")
   [:http-version :status]
   {}))

(fn read-status-line [src read-fn]
  "Read the first line from the HTTP response and parse it.
Uses `read-fn` on the `src` to obtain the data."
  (parse-status-line (read-fn src)))

(fn parse-header [line]
  "Parse a single header from a `line`."
  (let [(header value) (line:match " *([^:]+) *: *(.*)")]
    (values header (try-tonumber value))))

(fn read-headers [src read-fn ?headers]
  "Read and parse HTTP headers.
Uses `read-fn` on the `src` to obtain the data.  The optional
parameter `?headers` is used for tail recursion, and should not be
provided by the caller, unless the intention is to append or override
existing headers."
  (let [headers (or ?headers {})
        line (read-fn src)]
    (case line
      (where (or "\r" ""))
      headers
      _ (read-headers
         src
         read-fn
         (let [(header value) (parse-header line)]
           (doto headers (tset (capitalize-header header) value)))))))

(fn parse-http-response [src {: receive-fn : read : as}]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `receive`
callback.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-status-line src receive-fn)
        headers (read-headers src receive-fn)
        stream (->> {:__index {:close #(src:close)
                               :read (fn [_ pattern]
                                       (set read.fn (make-read-fn pattern))
                                       (receive-fn src))}
                     :__close #(src:close)
                     :__name "Stream"
                     :__fennelview #(.. "#<" (: (tostring $) :gsub "table:" "Stream:") ">")}
                    (setmetatable {}))]
    (doto status
      (tset :headers headers)
      (tset :body (case as
                    :raw (stream:read (or headers.Content-Length :*a))
                    :stream stream
                    :ltn12 (ltn12.source! src))))))

;;; URL parsing

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
        {: host : port : userinfo} (parse-authority
                                    (if scheme
                                        (url:match "//([^/]+)/")
                                        (url:match "^([^/]+)/")))
        scheme (or scheme "http")
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+/([^?#]+)")
        query (url:match "%?([^#]+)#?")
        fragment (url:match "#([^?]+)%??")]
    {: scheme : host : port : userinfo : path : query : fragment}))

(fn format-path [{: path : query : fragment}]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL."
  (.. "/" (or path "") (if query (.. "?" query) "") (if fragment (.. "?" fragment) "")))

;;; HTTP

(local http {})

(fn http.request [method url ?opts]
  "Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is an instance of a `promise-chan`, and the body must
  be read inside of a `go` block.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional string body.
- `:as` - how to coerce the output.

Several options available for the `as` key:

- `:ltn12` - the body will be a ltn12 source
- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.

When supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made."
  (let [{: host : port &as parsed} (parse-url url)
        opts (collect [k v (pairs (or ?opts {}))
                       :into {:as :raw
                              :async? false}]
               k v)
        headers (collect [k v (pairs (or opts.headers {}))
                          :into {:host
                                 (.. host (if port (.. ":" port) ""))
                                 :content-length
                                 (case opts.body
                                   (where body (= :string (type body)))
                                   (length body))}]
                  k v)
        path (format-path parsed)
        req (make-http-request method path headers opts.body)
        read {}
        _ (set read.fn (make-read-fn :*l))
        chan (tcp.chan parsed nil nil (fn [socket] (read.fn socket)))
        res (promise-chan)]
    (if opts.async?
        (do (go (>! chan req)
                (>! res (parse-http-response chan {:receive-fn <! : read :as opts.as})))
            res)
        (do (>!! chan req)
            (parse-http-response chan {:receive-fn <!! : read :as opts.as})))))

(macro define-http-method [method]
  "Defines an HTTP method for the given `method`."
  `(fn ,(sym (.. :http. (tostring method)))
     [url# opts#]
     {:fnl/arglist [url opts]
      :fnl/docstring ,(.. "Makes a `" (string.upper (tostring method))
                          "` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is an instance of a `promise-chan`, and the body must
  be read inside of a `go` block.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional string body.
- `:as` - how to coerce the output.

Several options available for the `as` key:

- `:ltn12` - the body will be a ltn12 source
- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.

When supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made.")}
     (http.request ,(tostring method) url# opts#)))

(define-http-method get)
(define-http-method post)
(define-http-method put)
(define-http-method patch)
(define-http-method options)
(define-http-method trace)
(define-http-method head)
(define-http-method delete)
(define-http-method connect)

{: http
 : ltn12}
