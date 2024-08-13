(local {: server} (require :http))

(fn handler [{: path : headers &as request}]
  (case path
    "/" (let [url (.. "http://" headers.Host "/index.html")
              body (.. "<!DOCTYPE HTML>"
                       "<title>Redirecting...</title><h1>Redirecting...</h1>"
                       "<p>You should be redirected automatically to target URL: "
                       "<a href=\"" url "\">" url "</a>.  If not click the link.</p>")]
          {:status 302
           :headers {:connection "close"
                     :location "/index.html"
                     :content-length (length body)}
           :body body})
    _ (case (io.open (.. "." path))
        file {:status 200
              :headers {:connection (or headers.Connection :keep-alive)
                        :transfer-encoding :chunked
                        :content-type (case (path:match "%.(.-)$")
                                        :html :text/html
                                        :ico :image/x-icon
                                        _ :application/octet-stream)}
              :body file}
        _ (let [body "404: not found"]
            {:status 404
             :headers {:connection (or headers.Connection "keep-alive")
                       :content-length (length body)
                       :content-type "text/plain"}
             :body body}))))

(local server
  (server.start-server handler {:port 12345}))

(server:wait)
