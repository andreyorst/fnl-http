(require-macros (doto :lib.fennel-test require))

(local {: skip-test}
  (require :lib.fennel-test))

(local http
  (require :http.client))

(local readers
  (require :http.readers))

(local json
  (require :http.json))

(local a
  (require :lib.async))

(var port 8001)

(fn url [path]
  (.. "http://localhost:" port (or path "")))

(fn wait-for-server [attempts]
  (faccumulate [started? false i 1 attempts :until started?]
    (or (pcall http.head (url)
               {:headers {:connection "close"}})
        (a.<!! (a.timeout 100)))))

(fn kill [pid]
  (with-open [_ (io.popen (.. "kill -9 " pid " >/dev/null 2>&1"))]))

(fn select-keys [tbl keys]
  (collect [_ k (ipairs keys)]
    k (. tbl k)))

(use-fixtures
 :once
 (fn [t]
   (when (os.getenv :SKIP_INTEGRATION)
     (skip-test "skipping long test"))
   (with-open [proc (io.popen (.. "podman run  -p " port ":80 kennethreitz/httpbin >/dev/null 2>&1 & echo $!"))]
     (let [pid (proc:read :*l)
           attempts 10]
       (if (wait-for-server attempts)
           (do (t)
               (kill pid))
           (do (kill pid)
               (skip-test (.. "coudln't connect to httpbin server after " attempts " attempts") false)))))))

(fn cleanup-response [resp]
  (if (= :table (type resp))
      (doto resp
        (tset :http-client nil)
        (tset :request-time nil)
        (tset :headers :Date nil)
        (tset :headers :Server nil))))

(deftest methods-test
  (testing "GET request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/get"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "POST request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :body "foo"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (let [resp (cleanup-response
                 (doto (http.post (url "/post") {:body "foo" :as :json})
                   (tset :length nil)
                   (tset :headers :Content-Length nil)))]
       (set resp.body resp.body.data)
       resp)))
  (testing "DELETE request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.delete (url "/delete"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "PATCH request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.patch (url "/patch"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "PUT request"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :body "foo"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (let [resp (cleanup-response
                 (doto (http.put (url "/put") {:body "foo" :as :json})
                   (tset :length nil)
                   (tset :headers :Content-Length nil)))]
       (set resp.body resp.body.data)
       resp))))

(deftest post-test
  (testing "POST raw data"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :body "foo"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (let [resp (cleanup-response
                 (doto (http.post (url "/post") {:body "foo" :as :json})
                   (tset :length nil)
                   (tset :headers :Content-Length nil)))]
       (set resp.body resp.body.data)
       resp)))
  (testing "POST stream data"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :body "foo"
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (let [resp (cleanup-response
                 (doto (http.post (url "/post") {:body (readers.string-reader "foo") :as :json})
                   (tset :length nil)
                   (tset :headers :Content-Length nil)))]
       (set resp.body resp.body.data)
       resp)))
  (testing "POST multipart data"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :body {:files {:baz "qux"} :form {:foo "bar"}}
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :trace-redirects []
      :reason-phrase "OK"
      :status 200}
     (let [resp (cleanup-response
                 (doto (http.post (url "/post")
                                  {:multipart
                                   [{:name "foo" :content "bar"}
                                    {:name "baz" :content "qux" :filename "baz.txt"}]
                                   :as :json})
                   (tset :length nil)
                   (tset :headers :Content-Length nil)))]
       (set resp.body (select-keys resp.body [:form :files]))
       resp))))

(deftest redirection-test
  (testing "basic redirection"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :trace-redirects [(url "/get")]
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/absolute-redirect/1"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "relative redirection"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :trace-redirects [(url "/get")]
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/relative-redirect/1"))
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
      :trace-redirects []
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "FOUND"
      :status 302}
     (cleanup-response
      (doto (http.get (url "/absolute-redirect/1") {:follow-redirects? false})
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil))))
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "text/html; charset=utf-8"
                :Location (url "/get")}
      :trace-redirects []
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "SEE OTHER"
      :status 303}
     (cleanup-response
      (doto (http.get (url "/redirect-to")
                      {:query-params {:url (url "/get")
                                      :status_code 303}
                       :follow-redirects? false
                       :as :json})
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "several redirects"
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :trace-redirects [(url "/absolute-redirect/2")
                        (url "/absolute-redirect/1")
                        (url "/get")]
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/absolute-redirect/3"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil))))
    (assert-eq
     {:headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Type "application/json"}
      :trace-redirects [(url "/relative-redirect/2")
                        (url "/relative-redirect/1")
                        (url "/get")]
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200}
     (cleanup-response
      (doto (http.get (url "/relative-redirect/3"))
        (tset :body nil)
        (tset :length nil)
        (tset :headers :Content-Length nil)))))
  (testing "redirect with the same method"
    (assert-eq
     "foo"
     (-> (url "/redirect-to")
         (http.post
          {:query-params
           {:url (url "/post")
            :status_code 307}
           :body "foo"
           :as :json})
         (. :body :data)))
    (assert-eq
     "foo"
     (-> (url "/redirect-to")
         (http.post
          {:query-params
           {:url (url "/post")
            :status_code 308}
           :body "foo"
           :as :json})
         (. :body :data))))
  (testing "redirect with the GET method"
    (assert-eq
     (url "/get")
     (-> (url "/redirect-to")
         (http.post
          {:query-params
           {:url (url "/get")
            :status_code 301}
           :as :json})
         (. :body :url))))
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
     (. (http.get (url "/json") {:as :json}) :body)))
  (testing "parsing json stream"
    (let [n 3]
      (assert-eq
       {:id 0 :url (url (.. "/stream/" n))}
       (-> (url (.. "/stream/" n))
           (http.get {:as :json})
           (. :body)
           (select-keys [:id :url])))))
  (testing "parsing json stream manually"
    (let [n 100]
      (assert-eq
       (fcollect [i 0 (- n 1)]
         {:id i :url (url (.. "/stream/" n))})
       (let [body (-> (url (.. "/stream/" n))
                      (http.get {:as :stream})
                      (. :body))]
         (fcollect [i 1 n]
           (select-keys (json.decode body) [:id :url])))))))

(deftest asynchronous-body-read-test
  (let [Timeout (setmetatable {} {:__fennelview #:Timeout})]
    (testing "Read a stream of bytes in multiple threads."
      (let [resp (http.get (url "/bytes/40000")
                           {:headers {:connection "close"}
                            :as :stream})
            done (a.chan)]
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
               (assert-ne Timeout)))))
    (testing "Read a chunked stream of bytes in multiple threads."
      (let [resp (http.get (url "/stream-bytes/40000")
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
               (assert-ne Timeout)))))))

(deftest delayed-response-test
  (testing "The response is delayed in fixed intervals"
    (assert-eq
     {:body "**********"
      :headers {:Access-Control-Allow-Credentials "true"
                :Access-Control-Allow-Origin "*"
                :Connection "keep-alive"
                :Content-Length "10"
                :Content-Type "application/octet-stream"}
      :length 10
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}}
     (cleanup-response
      (http.get
       (url "/drip")
       {:query-params
        {:duration 1 :numbytes 10 :code 200 :delay 1}})))))

(deftest request-inspection-test
  (testing "query params understood"
    (assert-eq
     {:a "1" :b "2"}
     (-> (url "/post")
         (http.post  {:query-params {:a "1" :b "2"} :as :json})
         (. :body :args)))
    (assert-eq
     {:a "1" :b "2" :c "3"}
     (-> (url "/post?a=1")
         (http.post {:query-params {:b "2" :c "3"} :as :json})
         (. :body :args)))
    (assert-eq
     {:a ["1" "2"] :c "3"}
     (-> (url "/post?a=1")
         (http.post {:query-params {:a "2" :c "3"} :as :json})
         (. :body :args)))
    (assert-eq
     {:a ["1" "2" "3"]}
     (-> (url "/post?a=1")
         (http.post {:query-params {:a ["2" "3"]} :as :json})
         (. :body :args)))))

(deftest errornous-response-test
  (testing "4XX codes"
    (each [_ method (ipairs [:delete :get :patch :post :put])]
      (let [request (. http method)]
        (for [code 400 499]
          (assert-not
           (pcall request (url (.. "/status/" code))))
          (assert-eq
           code
           (-> (url (.. "/status/" code))
               (request {:throw-errors? false})
               (. :status)))
          (let [resp (a.chan)]
            (request (url (.. "/status/" code))
                     {:async? true}
                     #nil #(a.>! resp $))
            (assert-eq code (. (a.<!! resp) :status)))
          (let [resp (a.chan)]
            (request (url (.. "/status/" code))
                     {:async? true :throw-errors? false}
                     #(a.>! resp $) #nil)
            (assert-eq code (. (a.<!! resp) :status)))))))
  (testing "5XX codes"
    (each [_ method (ipairs [:delete :get :patch :post :put])]
      (let [request (. http method)]
        (for [code 500 599]
          (assert-not
           (pcall request (url (.. "/status/" code))))
          (assert-eq
           code
           (-> (url (.. "/status/" code))
               (request {:throw-errors? false})
               (. :status)))
          (let [resp (a.chan)]
            (request (url (.. "/status/" code))
                     {:async? true}
                     #nil #(a.>! resp $))
            (assert-eq code (. (a.<!! resp) :status)))
          (let [resp (a.chan)]
            (request (url (.. "/status/" code))
                     {:async? true :throw-errors? false}
                     #(a.>! resp $) #nil)
            (assert-eq code (. (a.<!! resp) :status))))))))
