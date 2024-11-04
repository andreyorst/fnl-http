(local server (require :io.gitlab.andreyorst.fnl-http.server))
(local json (require :io.gitlab.andreyorst.json))

(fn handler [req]
  (case req
    {: parts}
    (set req.parts
      (icollect [part parts]
        (doto part (tset :content (part.content:read :*a)))))
    {: content}
    (set req.content
      (content:read (tonumber req.headers.Content-Length))))
  {:status 200
   :body (json req)})

(with-open [s (server.start handler {:port 8002})] (s:wait))
