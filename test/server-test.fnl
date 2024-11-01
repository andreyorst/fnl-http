(require-macros
 (doto :io.gitlab.andreyorst.fennel-test require))

(local {: skip-test}
  (require :io.gitlab.andreyorst.fennel-test))

(local http
  (require :io.gitlab.andreyorst.fnl-http.client))

(local readers
  (require :io.gitlab.andreyorst.fnl-http.readers))

(local json
  (require :io.gitlab.andreyorst.fnl-http.json))

(local a
  (require :io.gitlab.andreyorst.async))

(fn url [path]
  (.. "http://localhost:8002" (or path "")))

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
    (with-open [proc (io.popen (.. "fennel"
                                   " --add-fennel-path lib/?.fnl"
                                   " --add-fennel-path src/?.fnl"
                                   " test/data/server.fnl"
                                   " & echo $!"))]
      (let [pid (proc:read :*l)
            attempts 100]
        (if (wait-for-server attempts 8000)
            (do (t)
                (kill pid))
            (do (kill pid)
                (skip-test (.. "coudln't connect to echo server after " attempts " attempts") false)))))))

(fn cleanup-response [resp]
  (doto resp
    (tset :http-client nil)
    (tset :request-time nil)))

(deftest get-test
  (testing "simple GET"
    (assert-eq {:body {:headers {:Host "localhost:8002"} :http-version "HTTP/1.1" :method "GET" :path "/"}
                :headers {:Connection "keep-alive" :Content-Length "97"}
                :length 97
                :protocol-version {:major 1 :minor 1 :name "HTTP"}
                :reason-phrase "OK"
                :status 200
                :trace-redirects {}}
               (cleanup-response (http.get (url) {:as :json})))))

(deftest post-test
  (testing "POST string"
    (assert-eq
     {:body {:content "vaiv" :headers {:Content-Length "4" :Host "localhost:8002"} :http-version "HTTP/1.1" :method "POST" :path "/"}
      :headers {:Connection "keep-alive" :Content-Length "140"}
      :length 140
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}}
     (cleanup-response (http.post (url) {:body "vaiv" :as :json :throw-errors? false}))))
  (testing "POST file"
    (assert-eq
     {:body {:content "vaiv\n"
             :headers {:Content-Length "5" :Host "localhost:8002"}
             :http-version "HTTP/1.1"
             :method "POST"
             :path "/"}
      :headers {:Connection "keep-alive" :Content-Length "142"}
      :length 142
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}}
     (cleanup-response (http.post (url) {:body (readers.file-reader (io.open "test/data/sample" :r)) :as :json :throw-errors? false}))))
  (testing "POST multipart"
    (assert-eq
     {:body {:files {:sample "vaiv\n"}
             :form {:daun "kuku"}
             :headers {:Content-Length "347" :Content-Type "multipart/form-data; boundary=foobar" :Host "localhost:8002"}
             :http-version "HTTP/1.1"
             :method "POST"
             :path "/"}
      :headers {:Connection "keep-alive" :Content-Length "236"}
      :length 236
      :protocol-version {:major 1 :minor 1 :name "HTTP"}
      :reason-phrase "OK"
      :status 200
      :trace-redirects {}}
     (cleanup-response
      (http.post
       (url)
       {:multipart [{:name "daun" :content "kuku"}
                    {:filename "sample" :name "sample"
                     :content (readers.file-reader (io.open "test/data/sample" :r))}]
        :headers {:content-type "multipart/form-data; boundary=foobar"}
        :as :json
        :throw-errors? false})))))
