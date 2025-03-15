(local {: concat
        : insert
        : sort}
  table)

(fn urlencode [str allowed-char-pattern]
  "Percent-encode string `str`.
Accepts optional `allowed-char-pattern` to override default allowed
characters. The default pattern is `\"[^%w._~-]\"`."
  (assert (= :string (type str)) "expected string as a first argument")
  (pick-values 1
    (str:gsub (or allowed-char-pattern "[^%w._~-]")
              #(: "%%%X" :format ($:byte)))))

(fn sequential? [val ?max]
  {:private true}
  (and (= :table (type val))
       (case (length val)
         0 false
         len (let [max (or ?max len)]
               (case (next val max)
                 (where k (= :number (type k)))
                 (sequential? val k)
                 nil true
                 _ false)))))

(fn multi-param-entries [key vals]
  {:private true}
  (let [key (urlencode (tostring key))]
    (icollect [_ v (pairs vals)]
      (.. key "=" (urlencode (tostring v))))))

(fn sort-query-params [[k1] [k2]]
  {:private true}
  (< k1 k2))

(fn generate-query-string [params]
  (when params
    (let [ordered (doto (icollect [k v (pairs params)] [k v])
                    (sort sort-query-params))]
      (-> (accumulate [res [] _ [k v] (ipairs ordered)]
            (do (if (sequential? v)
                    (each [_ param (ipairs (multi-param-entries k v))]
                      (insert res param))
                    (->> (.. (urlencode (tostring k))
                             "="
                             (urlencode (tostring v)))
                         (insert res)))
                res))
          (concat "&")))))

(fn merge-query-params [?query-a ?query-b]
  {:private true}
  (when (or (not= nil ?query-a) (not= nil ?query-b))
    (accumulate [query (collect [k v (pairs (or ?query-a {}))] k v)
                 k v (pairs (or ?query-b {}))]
      (case (. query k)
        [_ &as t]
        (->> (doto query
               (tset k (if (sequential? v)
                           (icollect [_ val (ipairs v) :into t]
                             val)
                           (doto t (insert v))))))
        val (doto query
              (tset k (if (sequential? v)
                          (icollect [_ val* (ipairs v) :into [val]]
                            val*)
                          [val v])))
        nil (doto query (tset k v))))))

(fn parse-query-string [query]
  (when query
    (accumulate [res {} key-value (query:gmatch "[^&]+")]
      (let [(k v) (key-value:match "([^=]+)=?(.*)")]
        (doto res
          (tset k (case (. res k)
                    [_ &as t] (doto t (insert v))
                    val [val v]
                    nil v)))))))

(fn parse-authority [authority]
  "Parse the `authority` part of a URL."
  {:private true}
  (let [userinfo (authority:match "([^@]+)@")
        port (authority:match ":(%d+)")
        host (if userinfo
                 (authority:match (.. "@([^:?#]+)" (if port ":" "")))
                 (authority:match (.. "([^:?#]+)" (if port ":" ""))))]
    {: userinfo : port : host}))

(fn url->string [{: scheme : host : port
                  : userinfo : path
                  : query : fragment}]
  (.. scheme "://"
      (if userinfo
          (.. userinfo "@")
          "")
      host
      (if port
          (.. ":" port)
          "")
      (or path "")
      (case (generate-query-string query)
        query (.. "?" query)
        _ "")
      (if fragment
          (.. "#" fragment)
          "")))

(fn parse-url [url]
  "Parses a `url` string as URL.
Returns a table with `scheme`, `host`, `port`, `userinfo`, `path`,
`query`, and `fragment` fields from the URL.  If the `scheme` part of
the `url` is missing, the default `http` scheme is used.  If the
`port` part of the `url` is missing, the default port is used based on
the `scheme` part: `80` for the `http` and `443` for `https`.  Calling
`tostring` on parsed URL returns a string representation, but doesn't
guarantee the same order of query parameters."
  (let [scheme (url:match "^([^:]+)://")
        {: host : port : userinfo}
        (parse-authority
         (if scheme
             (url:match "//([^/]+)/?")
             (url:match "^([^/]+)/?")))
        [scheme url] (if scheme [scheme url]
                         ["http" (.. "http://" url)])
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+(/[^?#]*)")
        query (parse-query-string (url:match "%?([^#]+)#?"))
        fragment (url:match "#([^?]+)%??")]
    (setmetatable {: scheme : host : port : userinfo : path : query : fragment}
                  {:__tostring url->string})))

(fn format-path [{: path : query} query-params]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL, and optional  `query-params` table."
  (.. (or path "/")
      (if (or query query-params)
          (.. "?" (generate-query-string
                   (merge-query-params
                    query
                    query-params)))
          "")))

{: urlencode
 : parse-url
 : format-path}
