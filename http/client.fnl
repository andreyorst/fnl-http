(local socket
  (require :socket))

(import-macros
    {: go}
  (doto :lib.async require))

(local {: >! : <! : >!! : <!! : chan?}
  (require :lib.async))

(local {: >!? : <!?}
  (require :http.async-extras))

(local http-parser
  (require :http.parser))

(local tcp
  (require :http.tcp))

(local {: reader? : file-reader}
  (require :http.readers))

(local {: build-http-request}
  (require :http.builder))

(local {: stream-body
        : format-chunk
        : wrap-body
        : multipart-content-length
        : stream-multipart}
  (require :http.body))

(local {: random-uuid}
  (require :http.uuid))

(local client {})

;;; Helper functions

(fn get-boundary [headers]
  (accumulate [boundary nil
               header value (pairs headers)
               :until boundary]
    (when (= "content-type" (string.lower header))
      (string.match value "boundary=([^;]+)"))))

(fn prepare-headers [host port {: body : headers : multipart : mime-subtype}]
  "Consttruct headers with some default ones inferred from `body`,
`headers`, `host`, `port`, and `multipart` body.  `mime-subtype` is
used to indicate `multipart` subtype, the default is `form-data`."
  (let [headers (collect [k v (pairs (or headers {}))
                          :into {:host (.. host (if port (.. ":" port) ""))
                                 :content-length (if (= (type body) :string)
                                                     (length body)
                                                     (reader? body)
                                                     (body:length))
                                 :transfer-encoding (case (type body) (where (or :string :nil)) nil _ "chunked")
                                 :content-type (when multipart
                                                 (.. "multipart/" (or mime-subtype "form-data") "; boundary=------------" (random-uuid)))}]
                  k v)
        headers (if multipart
                    (doto headers
                      (->> (get-boundary headers)
                           (multipart-content-length multipart)
                           (tset headers :content-length)))
                    headers)]
    (if (and (not multipart)
             (chan? body))
        ;; force chunked encoding for channels supplied as a body
        (doto headers
          (tset :content-length nil)
          (tset :transfer-encoding "chunked"))
        ;; force streaming for readers if content-length was supplied
        (and (not multipart)
             (reader? body)
             headers.content-length)
        (doto headers
          (tset :transfer-encoding nil))
        headers)))

(fn format-path [{: path : query : fragment}]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL."
  (.. (or path "/")
      (if query (.. "?" query) "")
      (if fragment (.. "?" fragment) "")))

(fn wrap-client [chan]
  "Adds a bunch of methods to the socket-channel to act like Luasocket
client object."
  (doto chan
    (tset :read (fn [src pattern]
                  (src:set-chunk-size pattern)
                  (<!? src)))
    (tset :receive (fn [src pattern prefix]
                     (src:set-chunk-size pattern)
                     (.. (or prefix "") (<!? src))))
    (tset :send (fn [ch data ...]
                  (->> (case (values (select :# ...) ...)
                         0 data
                         (1 i) (string.sub data i (length data))
                         _ (string.sub data ...))
                       (>!? ch))))
    (tset :write >!?)))

(fn client.request [method url ?opts ?on-response ?on-raise]
  {:fnl/arglist [method url opts on-response on-raise]
   :fnl/docstring "Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `headers` - a table with the HTTP headers for the request
- `body` - an optional body.
- `as` - how to coerce the body of the response.
- `throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.
- `multipart` - a sequential table of parts.

Several options available for the `as` key:

- `stream` - the body will be a stream object with a `read` method.
- `raw` - the body will be a string.
  This is the default value for `as`.
- `json` - the body will be parsed as JSON.

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
        headers (prepare-headers host port opts)
        req (build-http-request
             method
             (format-path parsed)
             headers
             (if opts.multipart
                 nil
                 (and body (= headers.transfer-encoding "chunked"))
                 (let [(_ data) (format-chunk body)]
                   data)
                 (= :string (type body))
                 body))
        client (->> (when (and opts.async?)
                      (fn [err]
                        (?on-raise err)
                        nil))
                    (tcp.chan parsed nil)
                    wrap-client)]
    (when opts.async?
      (assert
       (and ?on-response ?on-raise)
       "If :async? is true, you must pass on-response and on-raise callbacks"))
    (if opts.async?
        (go (set opts.start (socket.gettime))
            (client:write req)
            (case opts.multipart
              multipart (stream-multipart client multipart (get-boundary headers))
              _ (stream-body client body headers))
            (case (pcall http-parser.parse-http-response client opts)
              (true resp) (?on-response resp)
              (_ err) (?on-raise err)))
        (do (set opts.start (socket.gettime))
            (client:write req)
            (case opts.multipart
              multipart (stream-multipart client multipart (get-boundary headers))
              _ (stream-body client body headers))
            (http-parser.parse-http-response
             client
             opts)))))

(macro define-http-method [method]
  "Defines an HTTP method for the given `method`."
  `(fn ,(sym (.. :client. method))
     [url# opts# on-response# on-raise#]
     {:fnl/arglist [url opts on-response on-raise]
      :fnl/docstring ,(.. "Makes a `" (string.upper method)
                          "` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `async?` - a boolean, whether the request should be asynchronous.
  The result is a channel, that can be awaited.  The successful
  response of a server is then passed to the `on-response` callback.
  In case of any error during request, the `on-raise` callback is
  called with the error message.
- `headers` - a table with the HTTP headers for the request
- `body` - an optional body.
- `as` - how to coerce the body of the response.
- `throw-errors?` - whether to throw errors on response statuses
  other than 200, 201, 202, 203, 204, 205, 206, 207, 300, 301, 302,
  303, 304, 307. Defaults to `true`.

Several options available for the `as` key:

- `stream` - the body will be a stream object with a `read` method.
- `raw` - the body will be a string.
  This is the default value for `as`.
- `json` - the body will be parsed as JSON.

The body can be a string, a channel, or a Reader object. When
supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made and the body is sent using chunked transfer encoding.")}
     (client.request ,method url# opts# on-response# on-raise#)))

(define-http-method :get)
(define-http-method :post)
(define-http-method :put)
(define-http-method :patch)
(define-http-method :options)
(define-http-method :trace)
(define-http-method :head)
(define-http-method :delete)
(define-http-method :connect)

client
