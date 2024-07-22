(local socket
  (require :socket))

(local {: <! : >! : <!! : >!! : close!
        : chan : chan? : promise-chan
        : tcp}
  (require :lib.async))

(import-macros
 {: go}
 (doto :lib.async require))

(local http-parser
  (require :http.parser))

(local utils
  (require :http.utils))

(local tcp
  (require :http.tcp))

(local {: reader? : file-reader}
  (require :http.readers))

(local {: build-http-response
        : encode-chunk
        : prepare-chunk
        : prepare-amount
        : build-http-request}
  (require :http.encoder))

;;; Helper functions

(fn make-read-fn [receive]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src pattern]
    (src:set-chunk-size pattern)
    (receive src)))

(fn send-chunk [dst send-fn data read-fn]
  (let [(more? data) (prepare-chunk data read-fn)]
    (send-fn dst data)
    more?))

(fn send-amount [dst send-fn data read-fn amount]
  (let [len (if (< 1024 amount) 1024 amount)
        data (prepare-amount data read-fn len)
        remaining (- amount len)]
    (send-fn dst data)
    (when (> remaining 0)
      remaining)))

(fn stream-body [dst body send receive
                 {: transfer-encoding : content-length}]
  (if (= transfer-encoding "chunked")
      (while (send-chunk dst send body receive) nil)
      (and content-length
           (reader? body))
      ((fn loop [remaining]
         (case (send-amount dst send body receive remaining)
           remaining (loop remaining)))
       content-length)))

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

(fn wrap-body [val]
  (case (type val)
    :table (if (chan? body) body
               (reader? body) body
               val)
    :userdata (case (getmetatable val)
                {:__name "FILE*"}
                (file-reader val)
                _ val)
    _ val))

(fn http.request [method url ?opts]
  "Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `:async?` - a boolean, whether the request should be asynchronous.
  The result is an instance of a `promise-chan`, and the body must
  be read inside of a `go` block.
- `:headers` - a table with the HTTP headers for the request
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.

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
are made and the body is sent using chunked transfer encoding."
  (let [{: host : port &as parsed} (http-parser.parse-url url)
        opts (collect [k v (pairs (or ?opts {}))
                       :into {:as :raw
                              :async? false
                              :time socket.gettime}]
               k v)
        body (wrap-body opts.body)
        headers (prepare-headers opts.headers body host port)
        req (build-http-request
             method
             (utils.format-path parsed)
             headers
             (if (and body (= headers.transfer-encoding "chunked"))
                 (let [(_ data) (prepare-chunk body (if opts.async? <! <!!))]
                   data)
                 (= :string (type body))
                 body))
        chan (tcp.chan parsed)]
    (if opts.async?
        (let [res (promise-chan)]
          (set opts.start (socket.gettime))
          (go (>! chan req)
              (when body
                (stream-body chan body >! <! headers))
              (>! res (http-parser.parse-http-response
                       (doto chan
                         (tset :read (make-read-fn <!)))
                       opts)))
          res)
        (do (set opts.start (socket.gettime))
            (>!! chan req)
            (when body
              (stream-body chan body >!! <!! headers))
            (http-parser.parse-http-response
             (doto chan
               (tset :read (make-read-fn <!!)))
             opts)))))

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
- `:body` - an optional body.
- `:as` - how to coerce the body of the response.

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

http
