(local {: gettime}
  (require :socket))

(import-macros
    {: go}
  (doto :lib.async require))

(local {: >! : <! : >!! : <!! : chan?}
  (require :lib.async))

(local {: >!? : <!?}
  (require :http.async-extras))

(local {: chunked-encoding?
        : parse-http-response}
  (require :http.parser))

(local {: parse-url
        : format-path}
  (require :http.url))

(local {: chan}
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

(local {: decode}
  (require :http.json))

(local {: format
        : lower
        : upper}
  string)

(local client {})

;;; Helper functions

(fn get-boundary [headers]
  {:private true}
  (accumulate [boundary nil
               header value (pairs headers)
               :until boundary]
    (when (= "content-type" (lower header))
      (value:match "boundary=([^;]+)"))))

(fn prepare-headers [{: body : headers : multipart : mime-subtype :url {: host : port}}]
  "Consttruct headers with some default ones inferred from `body`,
`headers`, `host`, `port`, and `multipart` body.  `mime-subtype` is
used to indicate `multipart` subtype, the default is `form-data`."
  {:private true}
  (let [headers (collect [k v (pairs (or headers {}))
                          :into {:host (.. host (if port (.. ":" port) ""))
                                 :content-length (if (= (type body) :string)
                                                     (length body)
                                                     (reader? body)
                                                     (body:length))
                                 :transfer-encoding (case (type body)
                                                      (where (or :string :nil)) nil
                                                      _ "chunked")
                                 :content-type (when multipart
                                                 (.. "multipart/" (or mime-subtype "form-data")
                                                     "; boundary=------------" (random-uuid)))}]
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

(fn make-client [opts]
  "Creates a socket-channel based of `opts`. Adds a bunch of methods to
act like Luasocket client object."
  {:private true}
  (or opts.http-client
      (doto (chan opts.url nil
                  (when (and opts.async?)
                    (fn [err]
                      (opts.on-raise err)
                      nil)))
        (tset :read (fn [src pattern]
                      (src.set-chunk-size pattern)
                      (<!? src)))
        (tset :receive (fn [src pattern prefix]
                         (src.set-chunk-size pattern)
                         (.. (or prefix "") (<!? src))))
        (tset :send (fn [ch data ...]
                      (->> (case (values (select :# ...) ...)
                             0 data
                             (1 i) (data:sub i (length data))
                             _ (data:sub ...))
                           (>!? ch))))
        (tset :write >!?))))

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

(fn try-coerce-body [response opts]
  (if (= :table (type response))
      (case (values opts.as response.body)
        (:json body) (pcall decode body)
        (_ ?body) (values true ?body))
      (values true response)))

(fn raise* [response opts]
  {:private true}
  (if opts.async?
      (opts.on-raise response)
      (error response)))

(fn respond* [response opts]
  {:private true}
  (if opts.async?
      (opts.on-response response)
      response))

(fn respond [response opts]
  (let [(ok? body) (try-coerce-body response opts)
        response (if ok?
                     (doto response
                       (tset :parsed-headers nil)
                       (tset :body body))
                     body)]
    (if (or (not ok?)
            (and opts.throw-errors?
                 (not (. non-error-statuses response.status))))
        (raise* response opts)
        (respond* response opts))))

(fn raise [response opts]
  (let [(ok? body) (try-coerce-body response opts)
        response (if (and ok? (= :table (type response)))
                     (doto response
                       (tset :parsed-headers nil)
                       (tset :body body))
                     body)]
    (raise* response opts)))

(fn redirect? [status]
  {:private true}
  (<= 300 status 399))

(fn reuse-client? [{: body : http-client : headers :length len}]
  "Based on the response, check if `http-client` should be reused or closed.
Consumes the `body` of the response, if provided."
  {:private true}
  (when (reader? body)
    ;; consume body
    (if len
        (body:read len)
        (chunked-encoding? headers.Transfer-Encoding)
        (body:read :*a)))
  (case (lower headers.Connection)
    "keep-alive" http-client
    _ (do (when (reader? body)
            ;; read the rest of the stream
            (body:read :*a))
          (http-client:close)
          nil)))

(fn redirect [response opts request-fn location method]
  "Issues a redirection request.
If `method` is specifiyed, uses the given method for a new request.
The `opts` table is modified to contain a proper method, http-client,
`location`, and decrements redirect limit.  Accepts the `request-fn`
function to issue a new request."
  {:private true}
  (request-fn
   (doto (collect [k v (pairs opts)] k v)
     (tset :method (or method opts.method))
     (tset :http-client (reuse-client? response))
     (tset :query-params nil)
     (tset :url (parse-url location))
     (tset :max-redirects (- opts.max-redirects 1)))))

(fn follow-redirects [{: status : headers &as response}
                      {: method  : throw-errors?
                       : max-redirects : force-redirects?
                       &as opts}
                      request-fn]
  "Decides whether to follow a redirect `response`.
Based on `status` and response `headers` issues a specifiyed `method`
request to a new location, unless `max-redirects` is not `0`. If
`force-redirects?` is specifiyed, can issue original request again, in
case of receiving `307` or `308` statuses.  Accepts the `request-fn`
to issue a new request."
  {:private true}
  (if (or (not opts.follow-redirects?)
          (not (redirect? status)))
      (respond response opts)
      (case headers.Location
        nil
        (respond response opts)
        location
        (if (<= max-redirects 0)
            (if opts.throw-errors?
                (raise "too many redirects" opts)
                (respond response opts))
            (or (= 301 status)
                (= 302 status))
            (if (or (= :GET method)
                    (= :HEAD method))
                (redirect response opts request-fn location)
                (redirect response opts request-fn location :GET))
            (= 303 status)
            (redirect response opts request-fn location :GET)
            (or (= 307 status)
                (= 308 status))
            (redirect response opts request-fn location)
            (respond response opts)))))

(fn process-request [client request body headers opts request-fn]
  "Sends the `request` to the `client`, along with the `body` and
`headers`, based on `opts`.  Accepts the `request-fn` to retry the
request in case of redirection."
  {:private true}
  (client:write request)
  (stream-body client body headers)
  (case opts.multipart
    parts (stream-multipart client parts (get-boundary headers)))
  (if opts.async?
      (case (pcall parse-http-response client opts)
        (true resp) (follow-redirects resp opts request-fn)
        (_ err) (opts.on-raise err))
      (-> (parse-http-response client opts)
          (follow-redirects opts request-fn))))

(fn request* [opts]
  {:private true}
  (let [body (wrap-body opts.body)
        headers (prepare-headers opts)
        req (build-http-request
             opts.method
             (format-path opts.url opts.query-params)
             headers
             (if (= headers.transfer-encoding "chunked")
                 nil
                 (= :string (type body))
                 body))
        client (make-client opts)]
    (assert (or (not opts.async?) (and opts.on-response opts.on-raise))
            "If async? is true, on-response and on-raise callbacks must be passed")
    (set opts.start (or opts.start (gettime)))
    (if opts.async?
        (go (process-request client req body headers opts request*))
        (process-request client req body headers opts request*))))

(fn client.request [method url opts on-response on-raise]
  "Makes a `method` request to the `url`, returns the parsed response,
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
- `http-client` - a client object from the `http-client` field of the
  response to use with persistent connections.
- `follow-redirects?` - whether to follow redirects automaticaally.
  Defaults to `true`.
- `max-redirects` - how many redirects to follow.
- `query-params` - a table of query parameters to append to the `url`.

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
are made and the body is sent using chunked transfer encoding."
  (request*
   (doto (collect [k v (pairs (or opts {}))
                   :into {:as :raw
                          :async? false
                          :time gettime
                          :throw-errors? true
                          :follow-redirects? true
                          :max-redirects math.huge
                          :url (parse-url url)
                          :on-response on-response
                          :on-raise on-raise}]
           k v)
     (tset :method (upper method)))))

(macro define-http-method [method]
  "Defines an HTTP method for the given `method`."
  `(fn ,(sym (.. :client. method)) [url# opts# on-response# on-raise#]
     {:fnl/arglist [url opts on-response on-raise]
      :fnl/docstring ,(.. "Makes a `" (method:upper)
                          " request to the `url`, returns the parsed response,
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
- `http-client` - a client object from the `http-client` field of the
  response to use with persistent connections.
- `follow-redirects?` - whether to follow redirects automaticaally.
  Defaults to `true`.
- `max-redirects` - how many redirects to follow.
- `query-params` - a table of query parameters to append to the `url`.

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
