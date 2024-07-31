(local {: concat
        : insert
        : sort}
  table)

(fn urlencode-string [str]
  "Percent-encode string `str`."
  (pick-values 1
    (str:gsub "[^%w]" #(: "%%%X" :format ($:byte)))))

(fn object? [val]
  {:private true}
  (= :table (type val)))

(fn array? [val ?max]
  {:private true}
  (and (object? val)
       (case (length val)
         0 false
         len (let [max (or ?max len)]
               (case (next val max)
                 (where k (= :number (type k)))
                 (array? val k)
                 nil true
                 _ false)))))

(fn multi-param-entries [key vals]
  (let [key (urlencode-string (tostring key))]
    (icollect [_ v (pairs vals)]
      (.. key "=" (urlencode-string (tostring v))))))

(fn sort-query-params [h1 h2]
  {:private true}
  (< (h1:match "^[^=]+") (h2:match "^[^=]+")))

(fn generate-query-string [params]
  (when params
    (-> (accumulate [res [] k v (pairs params)]
          (do (if (array? v)
                  (each [_ param (ipairs (multi-param-entries k v))]
                    (insert res param))
                  (->> (.. (urlencode-string (tostring k))
                           "="
                           (urlencode-string (tostring v)))
                       (insert res)))
              res))
        (doto (sort sort-query-params))
        (concat "&"))))

(fn merge-query-params [...]
  (case (values (select :# ...) ...)
    0 nil
    1 ...
    (_ query-a query-b)
    (merge-query-params
     (accumulate [query (collect [k v (pairs query-a)] k v)
                  k v (pairs query-b)]
       (case (. query k)
         [val &as t]
         (->> (doto query
                (tset k (if (array? v)
                            (icollect [_ val (pairs v) :into t]
                              val)
                            (doto t (insert v))))))
         val (doto query (tset k [val v]))
         nil (doto query (tset k v))))
     (select 3 ...))))

(fn parse-query-string [query]
  (when query
    (accumulate [res {} key-value (query:gmatch "[^&]+")]
      (let [(k v) (key-value:match "([^=]+)=(.+)")]
        (doto res
          (tset k (case (. res k)
                    [val &as t] (doto t (insert v))
                    val [val v]
                    nil v)))))))

(fn parse-authority [authority]
  "Parse the `authority` part of a URL."
  {:private true}
  (let [userinfo (authority:match "([^@]+)@")
        port (authority:match ":(%d+)")
        host (if userinfo
                 (authority:match (.. "@([^:]+)" (if port ":" "")))
                 (authority:match (.. "([^:]+)" (if port ":" ""))))]
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
      (case (generate-query-string fragment)
        fragment (.. "#" fragment)
        _ "")))

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
             (url:match "//([^/]+)/?")
             (url:match "^([^/]+)/?")))
        [scheme url] (if scheme [scheme url]
                         ["http" (.. "http://" url)])
        port (or port (case scheme :https 443 :http 80))
        path (url:match "//[^/]+(/[^?#]*)")
        query (parse-query-string (url:match "%?([^#]+)#?"))
        fragment (parse-query-string (url:match "#([^?]+)%??"))]
    (setmetatable {: scheme : host : port : userinfo : path : query : fragment}
                  {:__tostring url->string
                   :__fennelview (fn [this] (.. "#url:\"" (tostring this) "\""))})))

(fn format-path [{: path : query : fragment} query-params]
  "Formats the PATH component of a HTTP `Path` header.
Accepts the `path`, `query`, and `fragment` parts from the parsed URL, and optional  `query-params` table."
  (.. (or path "/")
      (if (or query query-params)
          (.. "?" (generate-query-string (merge-query-params (or query {}) (or query-params {}))))
          "")
      (if fragment (.. "#" (generate-query-string fragment)) "")))

{: urlencode-string
 : parse-url
 : format-path}
