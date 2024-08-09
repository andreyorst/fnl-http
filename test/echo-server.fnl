(local socket
  (require :socket))

(local {: build-http-response}
  (require :http.builder))

(local {: parse-http-request}
  (require :http.parser))

(local {: post}
  (require :http.client))

(with-open [server (socket.bind "localhost" 8000)]
  (while true
    (with-open [client (server:accept)]
      (client:settimeout 1)
      (let [(_ _ request) (client:receive :*a)
            response (build-http-response 200 "OK" {:connection "close"} request)]
        (print request)
        (client:send response)))))
