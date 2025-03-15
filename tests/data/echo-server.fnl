(local socket
  (require :socket))

(local {: build-http-response}
  (require :io.gitlab.andreyorst.fnl-http.impl.builder))

(with-open [server (socket.bind "localhost" 8000)]
  (while true
    (with-open [client (server:accept)]
      (client:settimeout 1)
      (let [(_ _ request) (client:receive :*a)
            response (build-http-response 200 "OK" {:connection "close"} request)]
        (client:send response)))))
