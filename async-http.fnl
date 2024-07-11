(comment
 "MIT License

Copyright (c) 2024 Andrey Listopadov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
")

(local socket
  (require :socket))

(local {: make-reader
        &as reader}
  (require :reader))

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

(fn make-read-fn [receive]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src pattern]
    (src:set-chunk-size pattern)
    (receive src)))

;;; HTTP building

(local HTTP-VERSION "HTTP/1.1")

(fn build-http-request [method request-target ?headers ?content]
  "Formaths the HTTP request string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   (string.upper method)
   request-target
   HTTP-VERSION
   (or (headers->string ?headers) "")
   (or ?content "")))

(fn build-http-response [status reason ?headers ?content]
  "Formats the HTTP response string as per the HTTP/1.1 spec."
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   HTTP-VERSION
   (tostring status)
   reason
   (or (headers->string ?headers) "")
   (or ?content "")))

;;; Parsing

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
        line (read-fn src :*l)]
    (case line
      (where (or "\r" ""))
      headers
      _ (read-headers
         src
         read-fn
         (let [(header value) (parse-header line)]
           (doto headers (tset (capitalize-header header) value)))))))

;;;; HTTP Response

(fn parse-response-status-line [status]
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

(fn read-response-status-line [src read-fn]
  "Read the first line from the HTTP response and parse it.
Uses `read-fn` on the `src` to obtain the data."
  (parse-response-status-line (read-fn src :*l)))

(fn body-reader [src read-fn]
  (make-reader
   src
   {:read-bytes read-fn
    :read-line (fn [src]
                 (read-fn src :*l))
    :close (fn [src] (src:close))}))

(fn parse-http-response [src read-fn as]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `receive`
callback.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-response-status-line src read-fn)
        headers (read-headers src read-fn)
        stream (body-reader src read-fn)]
    (doto status
      (tset :headers headers)
      (tset :body (case as
                    :raw (stream:read (or headers.Content-Length :*a))
                    :stream stream
                    _ (error (string.format "unsupported coersion method '%s'" as)))))))

(comment
 (let [req (build-http-response 200 "OK" {:connection :close} "vaiv\ndaun\n")
       rdr (reader.string-reader req)
       {: body : headers : reason : status}
       (parse-http-response rdr (fn [src pattern] (src:read pattern)) :raw)]
   (= req (build-http-response status reason headers body)))
 )

;;;; HTTP Request

(fn parse-request-status-line [status]
  "Parse HTTP request status line."
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (doto res
                 (tset field (try-tonumber part)))))
       _ res))
   (status:gmatch "([^ ]+)")
   [:method :path :http-version]
   {}))

(fn read-request-status-line [src read-fn]
  "Read the first line from the HTTP response and parse it.
Uses `read-fn` on the `src` to obtain the data."
  (parse-request-status-line (read-fn src :*l)))

(fn parse-http-request [src read-fn]
  (let [status (read-request-status-line src read-fn)
        headers (read-headers src read-fn)]
    (doto status
      (tset :headers headers)
      (tset :content (read-fn src :*a)))))

(comment
 (let [req (build-http-request :get "/" {:connection :close} "vaiv\ndaun\n")
       rdr (reader.string-reader req)
       {: headers : method : path : content}
       (parse-http-request rdr (fn [src pattern] (src:read pattern)) rdr)]
   (= req (build-http-request method path headers content)))
 )

;;;; URL

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
        req (build-http-request method path headers opts.body)
        chan (tcp.chan parsed)]
    (if opts.async?
        (let [res (promise-chan)]
          (go (>! chan req)
              (>! res (parse-http-response
                       chan
                       (make-read-fn <!)
                       opts.as)))
          res)
        (do (>!! chan req)
            (parse-http-response
             chan
             (make-read-fn <!!)
             opts.as)))))

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

http
