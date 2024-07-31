(require-macros (doto :lib.fennel-test require))

(local {: parse-url}
  (require :http.url))

(deftest url-parse-test
  (testing "url parsing"
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"}
     (parse-url "scheme://author.ity"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :path "/"}
     (parse-url "scheme://author.ity/"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :path "/path"}
     (parse-url "scheme://author.ity/path"))
    (assert-eq
     {:host "author.ity"
      :scheme "scheme"
      :path "/more/path"}
     (parse-url "scheme://author.ity/more/path"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :port "1234"
      :path "/path"
      :query {:query "param"}
      :fragment {:fragment "param"}}
     (parse-url "scheme://author.ity:1234/path?query=param#fragment=param"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :port "1234"
      :path "/path"
      :query {:query1 "param" :query2 "param"}
      :fragment {:fragment1 "param" :fragment2 "param"}}
     (parse-url "scheme://author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :port "1234"
      :path "/path"
      :query {:query1 ["param1" "param2"]}}
     (parse-url "scheme://author.ity:1234/path?query1=param1&query1=param2"))
    (assert-eq
     {:scheme "scheme"
      :userinfo "user:password"
      :host "author.ity"
      :port "1234"
      :path "/path"
      :query {:query1 "param" :query2 "param"}
      :fragment {:fragment1 "param" :fragment2 "param"}}
     (parse-url "scheme://user:password@author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param"))))

(deftest url-roundtrip-test
  (testing "url parsing"
    (assert-eq
     "scheme://author.ity"
     (tostring (parse-url "scheme://author.ity")))
    (assert-eq
     "scheme://author.ity/"
     (tostring (parse-url "scheme://author.ity/")))
    (assert-eq
     "scheme://author.ity/path"
     (tostring (parse-url "scheme://author.ity/path")))
    (assert-eq
     "scheme://author.ity/more/path"
     (tostring (parse-url "scheme://author.ity/more/path")))
    (assert-eq
     "scheme://author.ity:1234/path?query=param#fragment=param"
     (tostring (parse-url "scheme://author.ity:1234/path?query=param#fragment=param")))
    (assert-eq
     "scheme://author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param"
     (tostring (parse-url "scheme://author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param")))
    (assert-eq
     "scheme://author.ity:1234/path?query1=param1&query1=param2"
     (tostring (parse-url "scheme://author.ity:1234/path?query1=param1&query1=param2")))
    (assert-eq
     "scheme://user:password@author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param"
     (tostring (parse-url "scheme://user:password@author.ity:1234/path?query1=param&query2=param#fragment1=param&fragment2=param")))))

(deftest defaults-test
  (testing "default scheme"
    (assert-eq "http" (. (parse-url "author.ity") :scheme)))
  (testing "default ports"
    (assert-eq
     {:scheme "http"
      :host "author.ity"
      :port 80}
     (parse-url "author.ity"))
    (assert-eq
     {:scheme "http"
      :host "author.ity"
      :port 80}
     (parse-url "http://author.ity"))
    (assert-eq
     {:scheme "https"
      :host "author.ity"
      :port 443}
     (parse-url "https://author.ity"))))

(deftest optional-delimiters-test
  (testing "empty port"
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :path "/"}
     (parse-url "scheme://author.ity:/")))
  (testing "empty userinfo password"
    (assert-eq
     {:scheme "scheme"
      :userinfo "user:"
      :host "author.ity"
      :path "/"}
     (parse-url "scheme://user:@author.ity/"))))
