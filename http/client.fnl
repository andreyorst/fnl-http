(local socket
  (require :socket))

(local {: >! : <! : >!! : <!!
        : chan? : main-thread?}
  (require :lib.async))

(fn <!? [port]
  "Takes a value from `port`.  Will return `nil` if closed.  Will block
if nothing is available and used on the main thread.  Will park if
nothing is available and used in the `go` block."
  (if (main-thread?)
      (<!! port)
      (<! port)))

(fn >!? [port val]
  "Puts a `val` into `port`.  `nil` values are not allowed.  Must be
called inside a `(go ...)` block.  Will park if no buffer space is
available.  Returns `true` unless `port` is already closed."
  (if (main-thread?)
      (>!! port val)
      (>! port val)))

(import-macros
    {: go}
  (doto :lib.async require))

(local http-parser
  (require :http.parser))

(local tcp
  (require :http.tcp))

(local {: reader? : file-reader}
  (require :http.readers))

(local {: build-http-request}
  (require :http.builder))

;;; Helper functions

(fn make-read-fn [receive]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src pattern]
    (src:set-chunk-size pattern)
    (receive src)))

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
    (send dst data)
    (when (> remaining 0)
      (stream-reader
       dst body send
       (- remaining (length data))))))

(fn stream-body [dst body send receive
                 {: transfer-encoding
                  : content-length}]
  "Stream the given `body` to `dst` using `send`.
Depending on values of the headers and the type of the `body`, decides
how to stream the data."
  (if (= transfer-encoding "chunked")
      (stream-chunks dst body send receive)
      (and content-length (reader? body))
      (stream-reader dst body send content-length)))

(local http (setmetatable {} {:__index {:version "0.0.1"}}))

(fn prepare-headers [?headers ?body host port]
  (let [headers (collect [k v (pairs (or ?headers {}))
                          :into {:host (.. host (if port (.. ":" port) ""))
                                 :content-length (case (type ?body) :string (length ?body))
                                 :transfer-encoding (case (type ?body) (where (or :string :nil)) nil _ "chunked")}]
                  k v)]
    (if (chan? ?body)
        ;; force chunked encoding for channels supplied as a body
        (doto headers
          (tset :content-length nil)
          (tset :transfer-encoding "chunked"))
        ;; force streaming for readers if content-length was supplied
        (and (reader? ?body)
             headers.content-length)
        (doto headers
          (tset :transfer-encoding nil))
        headers)))

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

(fn format-path [{: path : query : fragment}]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL."
  (.. (or path "/") (if query (.. "?" query) "") (if fragment (.. "?" fragment) "")))

(fn http.request [method url ?opts ?on-response ?on-raise]
  {:fnl/arglist [method url opts on-response on-raise]
   :fnl/docstring "Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding."}
  (let [{: host : port &as parsed} (http-parser.parse-url url)
        opts (collect [k v (pairs (or ?opts {}))
                       :into {:as :raw
                              :async? false
                              :time socket.gettime
                              :throw-errors? true}]
               k v)
        body (wrap-body opts.body)
        headers (prepare-headers opts.headers body host port)
        req (build-http-request
             method
             (format-path parsed)
             headers
             (if (and body (= headers.transfer-encoding "chunked"))
                 (let [(_ data) (format-chunk body <!?)]
                   data)
                 (= :string (type body))
                 body))
        chan (doto (tcp.chan parsed)
               (tset :read (make-read-fn <!?)))]
    (when opts.async?
      (assert
       (and ?on-response ?on-raise)
       "If :async? is true, you must pass on-response and on-raise callbacks"))
    (if opts.async?
        (go (set opts.start (socket.gettime))
            (>! chan req)
            (when body
              (stream-body chan body >! <! headers))
            (case (pcall http-parser.parse-http-response chan opts)
              (true resp) (?on-response resp)
              (_ err) (?on-raise err)))
        (do (set opts.start (socket.gettime))
            (>!! chan req)
            (when body
              (stream-body chan body >!! <!! headers))
            (http-parser.parse-http-response
             chan
             opts)))))

(macro define-http-method [method]
  "Defines an HTTP method for the given `method`."
  `(fn ,(sym (.. :http. (tostring method)))
     [url# opts# on-response# on-raise#]
     {:fnl/arglist [url opts on-response on-raise]
      :fnl/docstring ,(.. "Makes a `" (string.upper (tostring method))
                          "` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.
- `:throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.")}
     (http.request ,(tostring method) url# opts# on-response# on-raise#)))

(define-http-method get)
(define-http-method post)
(define-http-method put)
(define-http-method patch)
(define-http-method options)
(define-http-method trace)
(define-http-method head)
(define-http-method delete)
(define-http-method connect)

http
