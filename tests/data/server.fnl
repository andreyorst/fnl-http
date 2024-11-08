(local server (require :io.gitlab.andreyorst.fnl-http.server))
(local reader (require :io.gitlab.andreyorst.reader))
(local json (require :io.gitlab.andreyorst.json))

(fn handler [req]
  (case (values req.method req.path)
    ("GET" "/multipart")
    ;; raw multipart as a string
    {:status 200
     :headers {:content-type "multipart/form-data; boundary=foobar"}
     :body (: (io.open "tests/data/multipart") :read :*a)}
    ("GET" "/chunked-multipart")
    ;; proper multipart with chunking parts
    {:status 200
     :headers {:content-type "multipart/form-data; boundary=foobar"}
     :multipart [{:name "foo"
                  :content (io.open "tests/data/valid.json")}
                 {:name "bar" :content "bar"}]}
    ;; send the request back as JSON
    _ (do (case req
            {: parts}
            (set req.parts
              (icollect [part parts]
                (doto part (tset :content (part.content:read :*a)))))
            {: content}
            (set req.content
              (content:read (tonumber req.headers.Content-Length))))
          {:status 200
           :body (json req)})))

(with-open [s (server.start handler {:port 8002})] (s:wait))
