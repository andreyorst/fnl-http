(require-macros (doto :io.gitlab.andreyorst.fennel-test require))

(local {: parse-url
        : format-path
        : urlencode}
  (require :io.gitlab.andreyorst.fnl-http.url))

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
      :fragment "fragment=param"}
     (parse-url "scheme://author.ity:1234/path?query=param#fragment=param"))
    (assert-eq
     {:scheme "scheme"
      :host "author.ity"
      :port "1234"
      :path "/path"
      :query {:query1 "param" :query2 "param"}
      :fragment "fragment1=param&fragment2=param"}
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
      :fragment "fragment1=param&fragment2=param"}
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

(deftest format-path-test
  (testing "format path with no extra parameters"
    (assert-eq "/" (format-path {}))
    (assert-eq "/foo/bar" (format-path {:path "/foo/bar"})))
  (testing "format path with query parameters"
    (assert-eq "/?a=1&b=2" (format-path {:query {:a 1 :b 2}}))
    (assert-eq "/foo/bar?a=1&b=2" (format-path {:path "/foo/bar" :query {:a 1 :b 2}})))
  (testing "format path with array query parameters"
    (assert-eq
     "/foo/bar?a=1&a=1&a=1&b=2&b=2&b=2"
     (format-path {:path "/foo/bar" :query {:a [1 1 1] :b [2 2 2]}})))
  (testing "format path with array query parameters and external query"
    (assert-eq
     "/foo/bar?a=1&a=1&a=1&b=2&b=2&c=3&c=3"
     (format-path
      {:path "/foo/bar" :query {:a [1 1] :b [2]}}
      {:a 1 :b [2] :c [3 3]}))))

(deftest urlencode-test
  (testing "urlencode does nothing, when all characters are unreserved"
    (assert-eq "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
               (urlencode "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")))
  (testing "urlencode reserved characters"
    (assert-eq "%20" (urlencode " "))
    (assert-eq "%21%23%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40%5B%5D"
               (urlencode "!#$&'()*+,/:;=?@[]"))
    (assert-eq "%20%22%25%3C%3E%5C%5E%60%7B%7C%7D~%C2%A3%E2%82%AC"
               (urlencode " \"%<>\\^`{|}~£€"))))
