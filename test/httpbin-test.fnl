(require-macros (doto :lib.fennel-test require))

(local http
  (require :http))

(local a
  (require :lib.async))

(fn wait-for-server [{: host : port}]
  (var started? false)
  (for [i 1 10 :until started?]
    (set started?
      (or (pcall http.head
                 (.. (or host "localhost") ":" port)
                 {:headers {:connection "close"}})
          (a.<!! (a.timeout 500)))))
  started?)

(use-fixtures
 :once
 (fn [t]
   (let [port (+ 8100 (math.random 899))]
     (with-open [proc (io.popen (.. "podman run -p " port ":80 kennethreitz/httpbin >/dev/null 2>&1 & echo $!"))]
       (let [pid (proc:read :*a)]
         (if (wait-for-server {:host :localhost : port})
             (t)
             (io.stderr:write "Skipping httpbin-based tests after 10 unsuccessful attempts to connect\n"))
         (with-open [_ (io.popen (.. "kill -9 " pid))] nil))))))

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
      (doto (http.get "localhost:8001/get")
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil))))))
