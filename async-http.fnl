(local socket (require :socket))
(local a (require :async))
(import-macros {: go} (doto :async require))

(fn capitalize-header [header]
  "Capitalizes the header string."
  (-> (icollect [word (header:gmatch "[^-]+")]
        (word:gsub "^%l" string.upper))
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

(fn try-tonumber [value]
  "Tries to coerce a `value` to a number.
If coersion fails, returns the value as is."
  (case (tonumber value) n n _ value))

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
           (doto headers (tset header value)))))))

(fn make-read-fn [pattern]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src]
    (src:receive pattern)))

(fn parse-http-response [src receive read]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `receive`
callback.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-status-line src receive)
        headers (read-headers src receive)]
    (doto status
      (tset :headers headers)
      (tset :body
            (->> {:__index {:close #(src:close)
                            :read (fn [_ pattern]
                                    (set read.fn (make-read-fn pattern))
                                    (receive src))}
                  :__close #(src:close)}
                 (setmetatable {}))))))

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

(local http {})

(fn http.request [method url ?opts]
  "Makes a `method` request to the `url`, returns the parsed response,
containing a stream data of the response. The `method` is a string,
describing the HTTP method per the HTTP/1.1 spec. The `opts` is a
table containing the following keys:

- `async?` - a boolean, whether the request should be asynchronous.
  The result is an instance of a `promise-chan`, and the body must
  be read inside of a `go` block.
- `headers` - a table with the HTTP headers for the request
- `body` - an optional string body.

When supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made."
  (let [{: host : port &as parsed} (parse-url url)
        opts (or ?opts {})
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
        chan (a.tcp.chan parsed nil nil (fn [socket] (read.fn socket)))
        res (a.promise-chan)]
    (if opts.async?
        (do (go (a.>! chan req)
                (a.>! res (parse-http-response chan a.<! read)))
            res)
        (do (a.>!! chan req)
            (parse-http-response chan a.<!! read)))))

(macro define-http-method [method]
  "Defines an HTTP method for the given `method`."
  `(fn ,(sym (.. :http. (tostring method)))
     [url# opts#]
     {:fnl/arglist [url opts]
      :fnl/docstring
      ,(let [doc (.. "Makes a `" (string.upper (tostring method))
                     "` request to the `url`, returns the parsed response, containing a stream data of the response."
                     "The `opts` is a table containing the following keys:\n"
                     "|-\n"
                     "- `async?` - a boolean, whether the request should be asynchronous.\n"
                     "|-The result is an instance of a `promise-chan`, and the body must\n"
                     "|-be read inside of a `go` block.\n"
                     "- `headers` - a table with the HTTP headers for the request\n"
                     "- `body` - an optional string body.\n"
                     "|-\n"
                     "When supplying a non-string body, headers should contain a \"content-length\" key. "
                     "For a string body, if the \"content-length\" header is missing it is automatically determined by "
                     "calling the `length` function, ohterwise no attempts at detecting content-length are made.")]
         ;; nicer formatting for REPL
         (-> (icollect [line (doc:gmatch "[^\n]+")]
               (-> (accumulate [res {:len 0} s (line:gmatch "[^ ]+")]
                     (let [s (string.gsub s "%|%-" "  ")
                           len (+ res.len (length s))]
                       (if (>= len 60)
                           (doto res (table.insert (.. "\n" s)) (tset :len 0))
                           (doto res (table.insert s) (tset :len len)))))
                   (table.concat " ")))
             (table.concat "\n")))}
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
