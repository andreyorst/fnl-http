(import-macros {: go : go-loop}
  :io.gitlab.andreyorst.async)

(local {: reader?}
  (require :io.gitlab.andreyorst.reader))

(local socket
  (require :socket))

(local {: build-http-response}
  (require :io.gitlab.andreyorst.fnl-http.impl.builder))

(local {: parse-http-request}
  (require :io.gitlab.andreyorst.fnl-http.impl.parser))

(local {: chan? : timeout : <!}
  (require :io.gitlab.andreyorst.async))

(local {: socket->chan}
  (require :io.gitlab.andreyorst.fnl-http.impl.tcp))

(local {: decode-value
        : capitalize-header
        : get-boundary}
  (require :io.gitlab.andreyorst.fnl-http.impl.headers))

(local {: <!?
        : make-tcp-client
        : chunked-encoding?
        : multipart?}
  (require :io.gitlab.andreyorst.fnl-http.impl.utils))

(local {: stream-body
        : wrap-body
        : multipart-content-length
        : stream-multipart}
  (require :io.gitlab.andreyorst.fnl-http.impl.body))

(local {: random-uuid}
  (require :io.gitlab.andreyorst.uuid))

(local {: lower}
  string)

(local reason-phrases
  {100 "Continue"
   101 "Switching Protocols"
   102 "Processing"
   103 "Early Hints"
   200 "OK"
   201 "Created"
   202 "Accepted"
   203 "Non-Authoritative Information"
   204 "No Content"
   205 "Reset Content"
   206 "Partial Content"
   207 "Multi-Status"
   208 "Already Reported"
   226 "IM Used"
   300 "Multiple Choices"
   301 "Moved Permanently"
   302 "Found"
   303 "See Other"
   304 "Not Modified"
   305 "Use Proxy"
   306 "Switch Proxy"
   307 "Temporary Redirect"
   308 "Permanent Redirect"
   400 "Bad Request"
   401 "Unauthorized"
   402 "Payment Required"
   403 "Forbidden"
   404 "Not Found"
   405 "Method Not Allowed"
   406 "Not Acceptable"
   407 "Proxy Authentication Required"
   408 "Request Timeout"
   409 "Conflict"
   410 "Gone"
   411 "Length Required"
   412 "Precondition Failed"
   413 "Payload Too Large"
   414 "URI Too Long"
   415 "Unsupported Media Type"
   416 "Range Not Satisfiable"
   417 "Expectation Failed"
   418 "I'm a teapot"
   421 "Misdirected Request"
   422 "Unprocessable Content"
   423 "Locked"
   424 "Failed Dependency"
   425 "Too Early"
   426 "Upgrade Required"
   428 "Precondition Required"
   429 "Too Many Requests"
   431 "Request Header Fields Too Large"
   451 "Unavailable For Legal Reasons"
   500 "Internal Server Error"
   501 "Not Implemented"
   502 "Bad Gateway"
   503 "Service Unavailable"
   504 "Gateway Timeout"
   505 "HTTP Version Not Supported"
   506 "Variant Also Negotiates"
   507 "Insufficient Storage"
   508 "Loop Detected"
   510 "Not Extended"
   511 "Network Authentication Required"})

(fn respond [client ok? status reason headers body]
  {:private true}
  (let [status (or status
                   (if ok? 200 500))
        reason (or reason
                   (. reason-phrases status)
                   (if ok? "OK" "Internal Server Error"))]
    (client:write (build-http-response status reason headers))
    (case (type body)
      :string (client:write body)
      :nil nil
      _ (stream-body client body headers))))

(fn client-loop [client handler resources]
  {:private true}
  (go-loop []
    (case (parse-http-request client)
      request
      (let [request-headers
            (collect [k v (pairs (or request.headers {}))]
              (capitalize-header k) (decode-value v))
            (ok? resp) (pcall handler request)
            resp (if (and ok? (chan? resp)) (<! resp) resp)]
        (case (values ok? resp)
          (true {: status
                 :reason-phrase ?reason
                 :headers ?headers
                 :body ?body
                 :multipart ?multipart
                 :mime-subtype ?mime})
          (let [headers (collect [k v (pairs (or ?headers {}))]
                          (lower k) v)
                body (wrap-body ?body headers.content-type)
                headers (collect [k v (pairs headers)
                                  :into {:connection (or request-headers.Connection "keep-alive")
                                         :content-type (if ?multipart
                                                           (.. "multipart/" (or ?mime "form-data")
                                                               "; boundary=------------" (random-uuid))
                                                           (or (reader? body)
                                                               (chan? body))
                                                           "application/octet-stream")
                                         :content-length (if (= :string (type body))
                                                             (length body)
                                                             (and (= nil body) (= nil ?multipart))
                                                             0)
                                         :transfer-encoding (when (or (and (reader? body)
                                                                           (not (multipart? headers.content-type))
                                                                           (not headers.content-length))
                                                                      (chan? body))
                                                              "chunked")}]
                          (lower k) v)]
            (when (reader? body)
              (tset resources body true))
            (set headers.content-length
              (if (not (chunked-encoding? headers.transfer-encoding))
                  headers.content-length
                  ?multipart
                  (multipart-content-length ?multipart (get-boundary headers))))
            (respond client ok? status ?reason headers body)
            (when ?multipart
              (stream-multipart client ?multipart (get-boundary headers))))
          (false ?resp)
          (let [body (tostring (or ?resp ""))]
            (respond client ok? 500 "Internal server error"
                     {:content-type "text/plain"
                      :content-length (length body)}
                     body))
          (_ resp)
          (do (set request-headers.Connection "close")
              (respond client ok? 500 nil {:content-length 0 :connection "close"})
              (io.stderr:write
               "Server error: malformed handler response. Expected a table with status, headers, and body keys, got: "
               (case (type resp)
                 "table" ((. (or _G.package.loaded.fennel {:view #(tostring $)}) :view) resp {:one-line true})
                 Type Type)
               "\n")))
        (if (= request-headers.Connection "close")
            (client:close)
            (recur))))))

(fn start [handler conn]
  "Starts the server running the `handler` for each request.  Accepts
optional `conn` table, containing `host` and `port` for the server.

The `handler` is a function of one argument that receives the parsed
HTTP request. The return value of this function will be sent to the
client as a response.  Two formats of return values are supported:

1. `handler` can return the response body directly or throw it with
   the `error` function. In such cases, the response status is either
   `200` or `500`. If the response is a string, the content-length
   header field is calculated automatically. The response may also be
   a `reader`, an async.fnl channel or a file handle.

2. `handler` can return a table, containing the `status` field, and
   optional `headers`, `reason-phrase`, and `body` fields. The `body`
   field can contain the same kinds of values as above.

Note, the files and readers are automatically closed when the
connection to the client is closed. Readers also automatically close
when exhausted."
  (let [{: host : port} (or conn {})
        server (socket.bind (or host "localhost") (or port 0))]
    (server:settimeout 0)
    (var running? true)
    (let [thread (go-loop []
                   (when running?
                     (let [resources {}]
                       (case-try (server:accept)
                         client (client:settimeout 0)
                         _ (socket->chan
                            client nil
                            #(do (io.stderr:write $...) (io.stderr:write "\n")))
                         chan (make-tcp-client chan resources)
                         client (client-loop client handler resources)
                         (catch e (io.stderr:write e "\n"))))
                     (<! (timeout 10))
                     (recur)))]
      (fn close [_] (set running? false) (and (server:close) true))
      (setmetatable
       {:close close
        :stop close
        :server server
        :wait (fn [] (<!? thread))}
       {:__index (fn [_ field]
                   (case field
                     :host (pick-values 1 (server:getsockname))
                     :port (let [(_ port) (server:getsockname)]
                             (or (tonumber port) port))))
        :__close close
        :__name "tcp-server"
        :__fennelview #(.. "#<" (: (tostring $) :gsub "table" "tcp-server") ">")}))))

{: start}
