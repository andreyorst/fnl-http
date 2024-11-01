(local server (require :io.gitlab.andreyorst.fnl-http.server))
(local json (require :io.gitlab.andreyorst.fnl-http.json))

(fn handler [req]
  (case req
    {: parts}
    (do (each [part parts]
          (case part
            {: filename : content}
            (set req.files (doto (or req.files {}) (tset filename (content:read :*a))))
            {: name : content}
            (set req.form (doto (or req.form {}) (tset name (content:read :*a))))))
        (set req.parts nil))
    {: content}
    (doto req
      (tset :content (content:read (tonumber req.headers.Content-Length)))))
  {:status 200
   :body (json req)})

(with-open [s (server.start handler {:port 8002})] (s:wait))
