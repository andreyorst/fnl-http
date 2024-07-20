(require-macros (doto :lib.fennel-test require))

(local {: parse : json}
  (require :src.json))

(local readers
  (require :src.readers))

(deftest parse-valid
  (local valid (require :test.data.valid))
  (testing "parsing file"
           (let [parsed (parse (readers.file-reader "test/data/valid.json"))]
             (assert-eq valid parsed))))
