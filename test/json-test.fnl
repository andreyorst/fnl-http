(require-macros (doto :lib.fennel-test require))

(local {: decode : encode}
  (require :http.json))

(local readers
  (require :http.readers))

(deftest parse-valid-test
  (local valid (require :test.data.valid))
  (testing "parsing file"
    (let [parsed (decode (readers.file-reader "test/data/valid.json"))]
      (assert-eq valid parsed))))
