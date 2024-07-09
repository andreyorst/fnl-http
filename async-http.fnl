(local socket (require :socket))
(local a (require :async))
(import-macros {: go} (doto :async require))
(local view (. (require :fennel) :view))

(fn capitalize-header [s]
  (-> (icollect [word (s:gmatch "[^-]+")]
        (word:gsub "^%l" string.upper))
      (table.concat "-")))

(fn header->string [header value]
  (.. (capitalize-header header) ": " (tostring value) "\r\n"))

(fn headers->string [headers]
  (when (and headers (next headers))
    (-> (icollect [header value (pairs headers)]
          (header->string header value))
        table.concat)))

(local http-version "HTTP/1.1")

(fn make-http-request [method request-target ?headers ?content]
  (string.format "%s %s %s\r\n%s\r\n%s"
                 (string.upper method)
                 request-target
                 http-version
                 (or (headers->string ?headers) "")
                 (or ?content "")))

(fn make-http-response [status reason ?headers ?content]
  (string.format
   "%s %s %s\r\n%s\r\n%s"
   http-version
   (tostring status)
   reason
   (or (headers->string ?headers) "")
   (or ?content "")))

(fn try-tonumber [s]
  (case (tonumber s) n n _ s))

(fn parse-status-line [status]
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
  (parse-status-line (read-fn src)))

(fn parse-header [line]
  (let [(header value) (line:match " *([^:]+) *: *(.*)")]
    (values header (try-tonumber value))))

(fn read-headers [src read-fn ?headers]
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

(fn default-read-fn [src]
  (src:receive :*l))

(fn parse-http-response [src ?read-fn]
  (let [read-fn (or ?read-fn default-read-fn)
        status (read-status-line src read-fn)
        headers (read-headers src read-fn)]
    (doto status
      (tset :headers headers)
      (tset :body
            (->> {:__index {:close #(src:close)
                            :read #(read-fn src)}
                  :__close #(src:close)}
                 (setmetatable {}))))))

(fn parse-authority [authority]
      (let [userinfo (authority:match "([^@]+)@")
            port (authority:match ":(%d+)")
            host (if userinfo
                     (authority:match (.. "@([^:]+)" (if port ":" "")))
                     (authority:match (.. "([^:]+)" (if port ":" ""))))]
        {: userinfo : port : host}))

(fn parse-url [url]
  "Parses http(s) URLs."
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
  (.. "/" (or path "") (if query (.. "?" query) "") (if fragment (.. "?" fragment) "")))

(fn request [method url ?headers ?body]
  (let [{: host : port &as parsed} (parse-url url)
        headers (collect [k v (pairs (or ?headers {}))
                          :into {:host (.. host (if port (.. ":" port) ""))}]
                  k v)
        path (format-path parsed)
        req (make-http-request method path headers ?body)
        read {}
        read-chunk (fn [s]
                     (s:receive 1024))
        read-line (fn [s]
                    (let [(data-or-error message partial-result) (s:receive :*l)]
                      (case data-or-error
                        (where (or "" "\r"))
                        (do (set read.fn read-chunk)
                            data-or-error)
                        _
                        (values data-or-error message partial-result))))
        _ (set read.fn read-line)
        chan (a.tcp.chan parsed nil nil (fn [socket] (read.fn socket)))
        res (a.promise-chan)]
    (var split? true)
    (go (a.>! chan req)
        (a.>! res (parse-http-response chan a.<!)))
    res))

{: request}
