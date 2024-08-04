(require-macros (doto :lib.fennel-test require))

(local http
  (require :http))

(local a
  (require :lib.async))

(var port 8001)

(fn url [path]
  (.. "http://localhost:" port (or path "")))

(fn wait-for-server [port]
  (var started? false)
  (for [i 1 10 :until started?]
    (set started?
      (or (pcall http.head (url)
                 {:headers {:connection "close"}})
          (a.<!! (a.timeout 100)))))
  started?)

(fn kill [pid]
  (with-open [_ (io.popen (.. "kill -9 " pid " >/dev/null 2>&1"))] nil))

(use-fixtures
 :once
 (fn [t]
   ((fn loop [attempt]
      (if (< attempt 10)
          (do
            (set port (+ 8100 (math.random 899)))
            (with-open [proc (io.popen (.. "podman run  -p " port ":80 kennethreitz/httpbin >/dev/null 2>&1 & echo $!"))]
              (if (wait-for-server port)
                  (do (t)
                      (kill (proc:read :*l)))
                  (do (kill (proc:read :*l))
                      (loop (+ attempt 1))))))
          (io.write "skipping tests after 10 failed connection attempts: "))) 0)))

(fn cleanup-response [resp]
  (if (= :table (type resp))
      (doto resp
        (tset :http-client nil)
        (tset :request-time nil)
        (tset :headers :Date nil)
        (tset :headers :Server nil))))

(deftest get-test
  (testing "basic GET request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/get"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil))))))

(deftest redirection-test
  (testing "basic redirection"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/absolute-redirect/1"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "disabled redirection"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "text/html; charset=utf-8"
                :Location (url "/get")}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "FOUND"
      :status 302}
     (cleanup-response
      (doto (http.get (url "/absolute-redirect/1") {:follow-redirects? false})
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "too many redirects"
    (let [(ok? resp) (pcall http.get (url "/absolute-redirect/2") {:max-redirects 1})]
      (assert-not ok?)
      (assert-is (resp:match "too many redirects")))))

(deftest json-test
  (testing "parsing json response"
    (assert-eq
     {:slideshow
      {:author "Yours Truly"
       :date "date of publication"
       :slides [{:title "Wake up to WonderWidgets!"
                 :type "all"}
                {:items ["Why <em>WonderWidgets</em> are great"
                         "Who <em>buys</em> WonderWidgets"]
                 :title "Overview"
                 :type "all"}]
       :title "Sample Slide Show"}}
     (. (http.get (url "/json") {:as :json}) :body))))

(deftest asynchronous-body-read-test
  (testing "Read a stream of bytes in multiple threads."
    (let [resp (http.get (.. "http://localhost:" port "/stream-bytes/40000")
                         {:headers {:connection "close"}
                          :as :stream})
          done (a.chan)
          Timeout (setmetatable {} {:__fennelview #:Timeout})]
      (for [i 1 4]
        (a.go #(do (for [i 1 10]
                     (resp.body:read 1000))
                   (a.>! done i))))
      (for [i 1 4]
        (->> #(let [tout (a.timeout 1000)]
                (match (a.alts! [done tout])
                  [_ tout] Timeout
                  [val _] val))
             a.go
             a.<!!
             (assert-ne Timeout))))))
