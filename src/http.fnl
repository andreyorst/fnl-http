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

(local {: <! : >! : <!! : >!! : close!
        : chan : promise-chan
        : tcp}
  (include :async))

(import-macros
 {: go}
 (doto :async require))

(local http-parser
  (include :http-parser))

(local utils
  (include :utils))

(local tcp
  (include :tcp))

;;; Helper functions

(fn header->string [header value]
  "Converts `header` and `value` arguments into a valid HTTP header
string."
  (.. (utils.capitalize-header header) ": " (tostring value) "\r\n"))

(fn headers->string [headers]
  "Converts a `headers` table into a multiline string of HTTP headers."
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (header->string header value))
        table.concat)))

(fn make-read-fn [receive]
  "Returns a function that receives data from a socket by a given
`pattern`.  The `pattern` can be either `\"*l\"`, `\"*a\"`, or a
number of bytes to read."
  (fn [src pattern]
    (src:set-chunk-size pattern)
    (receive src)))

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

(local http (setmetatable {} {:__index {:version "0.0.1"}}))

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
- `:json` - the body will be parsed as JSON.

When supplying a non-string body, headers should contain a
\"content-length\" key. For a string body, if the \"content-length\"
header is missing it is automatically determined by calling the
`length` function, ohterwise no attempts at detecting content-length
are made."
  (let [{: host : port &as parsed} (http-parser.parse-url url)
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
        path (utils.format-path parsed)
        req (build-http-request method path headers opts.body)
        chan (tcp.chan parsed)]
    (doto opts
      (tset :start (socket.gettime))
      (tset :time socket.gettime))
    (if opts.async?
        (let [res (promise-chan)]
          (go (>! chan req)
              (>! res (http-parser.parse-http-response
                       chan
                       (make-read-fn <!)
                       opts)))
          res)
        (do (>!! chan req)
            (http-parser.parse-http-response
             chan
             (make-read-fn <!!)
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
- `:body` - an optional string body.
- `:as` - how to coerce the output.

Several options available for the `as` key:

- `:stream` - the body will be a stream object with a `read` method.
- `:raw` - the body will be a string.
  This is the default value for `as`.
- `:json` - the body will be parsed as JSON.

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
