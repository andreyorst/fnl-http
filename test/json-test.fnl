(require-macros (doto :lib.fennel-test require))

(local {: skip-test}
  (require :lib.fennel-test))

(local {: decode : encode}
  (require :http.json))

(local readers
  (require :http.readers))

(local body
  (require :http.body))

(deftest encode-test
  (testing "numbers and booleans stay the same"
    (assert-eq "1" (encode 1))
    (assert-eq "-1" (encode -1))
    (assert-eq "true" (encode true))
    (assert-eq "false" (encode false))
    (assert-eq "1.234567e+20" (encode 1.234567e+20)))
  (testing "nil is null"
    (assert-eq "null" (encode nil)))
  (testing "strings are encoded"
    (assert-eq "\"foo\"" (encode "foo"))
    (assert-eq "\"\\a\\b\\f\\v\\r\\t\\\\\\\"\\n\"" (encode "\a\b\f\v\r\t\\\"\n")))
  (testing "tables are encoded as objects"
    (assert-eq "{\"foo\": \"bar\"}" (encode {:foo "bar"})))
  (testing "sequential tables are encoded as arrays"
    (assert-eq "[\"foo\", \"bar\"]" (encode ["foo" "bar"])))
  (testing "empty tables are encoded as objects"
    (assert-eq "{}" (encode [])))
  (testing "functions are unencoded"
    (assert-not (pcall encode #nil))))

(deftest parse-test
  (testing "parsing from string"
    (assert-eq {:foo :bar :baz [1 2 3]}
               (decode "{\"foo\": \"bar\", \"baz\": [1, 2, 3], \"qux\": null}"))))

(deftest parse-reader-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "parsing from file"
    (assert-eq (require :test.data.valid)
               (decode (io.open "test/data/valid.json"))))
  (testing "parsing from file reader"
    (assert-eq (require :test.data.valid)
               (decode (readers.file-reader "test/data/valid.json"))))
  (testing "parsing from string reader"
    (assert-eq (require :test.data.valid)
               (decode (: (readers.file-reader "test/data/valid.json") :read :*a)))))

(deftest parse-body-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "parsing from body reader"
    (with-open [valid (io.open "test/data/valid.json")]
      (assert-eq (require :test.data.valid)
                 (decode (body.body-reader valid)))))
  (testing "parsing from chunked body reader"
    (with-open [chunked (io.open "test/data/chunked-body")]
      (assert-eq (require :test.data.valid)
                 (decode (body.chunked-body-reader chunked))))))

(deftest roundtrip-test
  (testing "numbers and booleans roundtrip"
    (assert-eq 1 (decode (encode 1)))
    (assert-eq -1 (decode (encode -1)))
    (assert-eq true (decode (encode true)))
    (assert-eq false (decode (encode false)))
    (assert-eq 1.234567e+20 (decode (encode 1.234567e+20))))
  (testing "nil is null"
    (assert-eq nil (decode (encode nil))))
  (testing "strings are encoded"
    (assert-eq "foo" (decode (encode "foo")))
    (assert-eq "\b\f\r\t\\\"\n" (decode (encode "\b\f\r\t\\\"\n"))))
  (testing "tables are encoded as objects"
    (assert-eq {:foo "bar"} (decode (encode {:foo "bar"}))))
  (testing "sequential tables are encoded as arrays"
    (assert-eq ["foo" "bar"] (decode (encode ["foo" "bar"]))))
  (testing "empty tables are encoded as objects"
    (assert-eq [] (decode (encode []))))
  (testing "parsing from file reader"
    (when _G.utf8
      (assert-eq (require :test.data.valid)
                 (decode (encode (require :test.data.valid)))))))

(deftest file-roundtrip-test
  (when (not _G.utf8)
    (skip-test "no utf8 module found"))
  (testing "encode decode Fennel data"
    (assert-eq (require :test.data.valid)
               (decode (encode (require :test.data.valid))))))
