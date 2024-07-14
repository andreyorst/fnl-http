(local {: make-reader
        &as reader}
  (include :reader))

(local json
  (include :json))

(local utils
  (include :utils))

(fn parse-header [line]
  "Parse a single header from a `line`."
  (case (line:match " *([^:]+) *: *(.*)")
    (header value) (values header value)))

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
         (case (parse-header (or line ""))
           (header value)
           (doto headers (tset header value)))))))

;;; HTTP Response

(fn parse-response-status-line [status]
  "Parse HTTP response status line."
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
                     (tset field (utils.as-data part))))
               ))
       _
       (let [reason (-> "%s/%s.%s +%s +"
                        (string.format res.protocol-version.name res.protocol-version.major res.protocol-version.minor res.status)
                        (status:gsub ""))]
         (doto res
           (tset :reason-phrase reason)))))
   (status:gmatch "([^ ]+)")
   [:protocol-version :status]
   {}))

(fn read-response-status-line [src read-fn]
  "Read the first line from the HTTP response and parse it.
Uses `read-fn` on the `src` to obtain the data."
  (parse-response-status-line (read-fn src :*l)))

(fn body-reader [src read-fn]
  (var buffer "")
  (make-reader
   src
   {:read-bytes (fn [src pattern]
                  (let [rdr (reader.string-reader buffer)
                        content (or (rdr:read pattern) "")]
                    (case pattern
                      (where n (= :number (type n)))
                      (let [len (length content)]
                        (set buffer (string.sub buffer (+ len 1)))
                        (if (= n len)
                            content
                            (.. content (or (read-fn src (- n len)) ""))))
                      (where (or :*l :l))
                      (let [read-more? (not (buffer:find "\n"))]
                        (set buffer (string.sub buffer (+ (length content) 1)))
                        (if read-more?
                            (.. content (or (read-fn src pattern) ""))
                            content))
                      (where (or :*a :a))
                      (do (set buffer "")
                          (.. content (or (read-fn src pattern) "")))
                      _ (error (tostring pattern)))))
    :read-line (fn [src]
                 (let [rdr (reader.string-reader buffer)
                       content (rdr:read :*l)
                       read-more? (not (string.find buffer "\n"))]
                   (set buffer (string.sub (+ (length content) 1)))
                   (if read-more?
                       (.. content (or (read-fn src :*l) ""))
                       content)))
    :close (fn [src] (src:close))
    :peek (fn [src bytes]
            (assert (= :number (type bytes)) "expected number of bytes to peek")
            (let [rdr (reader.string-reader buffer)
                  content (or (rdr:read bytes) "")
                  len (length content)]
              (if (= bytes len)
                  content
                  (let [data (read-fn src (- bytes len))]
                    (set buffer (.. buffer (or data "")))
                    buffer))))}))

(fn parse-http-response [src read-fn {: as : parse-headers? : start : time}]
  "Parse the beginning of the HTTP response.
Accepts `src` that is a source, that can be read with the `receive`
callback.  The `read` is a special storage to alter how `receive`
internaly reads the data inside the `read` method of the body.

Returns a map with the information about the HTTP response, including
its headers, and a body stream."
  (let [status (read-response-status-line src read-fn)
        headers (read-headers src read-fn)
        parsed-headers (collect [k v (pairs headers)]
                         (utils.capitalize-header k) (utils.as-data v))
        stream (body-reader src read-fn)]
    (doto status
      (tset :headers (if parse-headers?
                       parsed-headers
                       headers))
      (tset :length (tonumber parsed-headers.Content-Length))
      (tset :request-time
            (when (and start time)
              (math.ceil (* 1000 (- (time) start)))))
      (tset :body
            (case as
              :raw (stream:read (or headers.Content-Length :*a))
              :json (json.parse stream)
              :stream stream
              _ (error (string.format "unsupported coersion method '%s'" as)))))))

(comment
 (let [req (build-http-response 200 "OK" {:connection :close} "vaiv\ndaun\n")
       rdr (reader.string-reader req)
       {: body : headers : reason-phrase : status}
       (parse-http-response rdr (fn [src pattern] (src:read pattern)) {:as :raw})]
   (= req (build-http-response status reason-phrase headers body)))
 )

;;; HTTP Request

(fn parse-request-status-line [status]
  "Parse HTTP request status line."
  ((fn loop [reader fields res]
     (case fields
       [field & fields]
       (let [part (reader)]
         (loop reader fields
               (doto res
                 (tset field (utils.as-data part)))))
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

;;; URL

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

{: parse-http-response
 : parse-http-request
 : parse-url}
