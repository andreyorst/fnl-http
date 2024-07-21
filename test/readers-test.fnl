(require-macros (doto :lib.fennel-test require))

(local readers
  (require :src.readers))

(local (ltn? ltn12)
  (pcall require :ltn12))

(deftest reader?-test
  (testing "various readers"
    (assert-is (readers.reader? (readers.string-reader "")))
    (assert-is (readers.reader? (readers.file-reader (os.tmpname))))
    (when ltn?
      (assert-is (readers.reader? (readers.ltn12-reader (ltn12.source.string "")))))
    (assert-not (readers.reader? nil))
    (assert-not (readers.reader? {}))
    (assert-not (readers.reader? true))
    (assert-not (readers.reader? false))
    (assert-not (readers.reader? ""))))

(deftest string-reader-test
  (testing "read bytes"
    (let [rdr (readers.string-reader "foobar")]
      (assert-eq "foo" (rdr:read 3))
      (assert-eq "bar" (rdr:read 4))))
  (testing "read-lines"
    (let [rdr (readers.string-reader "foo\nbar\r\nbaz")]
      (assert-eq "foo" (rdr:read :*l))
      (assert-eq "bar" (rdr:read :l))
      (assert-eq "baz" (rdr:read :*l))))
  (testing "line iterator"
    (let [rdr (readers.string-reader "foo\nbar\r\nbaz")]
      (assert-eq ["foo" "bar" "baz"] (icollect [line (rdr:lines)] line))))
  (testing "read all data"
    (let [rdr (readers.string-reader "foo\nbar\r\nbaz")]
      (assert-eq "foo\nbar\r\nbaz" (rdr:read :*a))))
  (testing "peek doesn't modify reader position"
    (let [rdr (readers.string-reader "foo\nbar\r\nbaz")]
      (assert-eq "foo" (rdr:peek 3))
      (assert-eq "foo" (rdr:read 3))
      (assert-eq "\nba" (rdr:peek 3))
      (assert-eq "" (rdr:read :*l))
      (assert-eq "bar" (rdr:peek 3))
      (assert-eq "bar\r\nbaz" (rdr:read :*a))))
  (testing "closing reader returns nil on reads"
    (let [rdr (doto (readers.string-reader "foo\nbar\r\nbaz")
                (: :close))]
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read 3))
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read :*l))
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read :*a)))))

(deftest file-reader-test
  (let [file (os.tmpname)]
    (with-open [f (io.open file :w)]
      (f:write "foo\nbar\r\nbaz"))
    (testing "read bytes"
      (let [rdr (readers.file-reader file)]
        (assert-eq "foo" (rdr:read 3))
        (assert-eq "\nbar" (rdr:read 4))))
    (testing "read-lines"
      (with-open [rdr (readers.file-reader file)]
        (assert-eq "foo" (rdr:read :*l))
        (assert-eq "bar\r" (rdr:read :l))
        (assert-eq "baz" (rdr:read :*l))))
    (testing "line iterator"
      (with-open [rdr (readers.file-reader file)]
        (assert-eq ["foo" "bar\r" "baz"] (icollect [line (rdr:lines)] line))))
    (testing "read all data"
      (with-open [rdr (readers.file-reader file)]
        (assert-eq "foo\nbar\r\nbaz" (rdr:read :*a))))
    (testing "peek doesn't modify reader position"
      (with-open [rdr (readers.file-reader file)]
        (assert-eq "foo" (rdr:peek 3))
        (assert-eq "foo" (rdr:read 3))
        (assert-eq "\nba" (rdr:peek 3))
        (assert-eq "" (rdr:read :*l))
        (assert-eq "bar" (rdr:peek 3))
        (assert-eq "bar\r\nbaz" (rdr:read :*a))))
    (testing "closing reader returns nil on reads"
      (let [rdr (doto (readers.file-reader file)
                  (: :close))]
        (assert-eq nil (rdr:peek 3))
        (assert-eq nil (rdr:read 3))
        (assert-eq nil (rdr:peek 3))
        (assert-eq nil (rdr:read :*l))
        (assert-eq nil (rdr:peek 3))
        (assert-eq nil (rdr:read :*a))))))

(deftest ltn12-reader-test
  (testing "read bytes"
    (let [rdr (readers.ltn12-reader (ltn12.source.string "foobar"))]
      (assert-eq "foo" (rdr:read 3))
      (assert-eq "bar" (rdr:read 4))))
  (testing "read-lines"
    (let [rdr (readers.ltn12-reader (ltn12.source.string "foo\nbar\r\nbaz"))]
      (assert-eq "foo" (rdr:read :*l))
      (assert-eq "bar" (rdr:read :l))
      (assert-eq "baz" (rdr:read :*l))))
  (testing "line iterator"
    (let [rdr (readers.ltn12-reader (ltn12.source.string "foo\nbar\r\nbaz"))]
      (assert-eq ["foo" "bar" "baz"] (icollect [line (rdr:lines)] line))))
  (testing "read all data"
    (let [rdr (readers.ltn12-reader (ltn12.source.string "foo\nbar\r\nbaz"))]
      (assert-eq "foo\nbar\r\nbaz" (rdr:read :*a))))
  (testing "peek doesn't modify reader position"
    (let [rdr (readers.ltn12-reader (ltn12.source.string "foo\nbar\r\nbaz"))]
      (assert-eq "foo" (rdr:peek 3))
      (assert-eq "foo" (rdr:read 3))
      (assert-eq "\nba" (rdr:peek 3))
      (assert-eq "" (rdr:read :*l))
      (assert-eq "bar" (rdr:peek 3))
      (assert-eq "bar\r\nbaz" (rdr:read :*a))))
  (testing "closing reader returns nil on reads"
    (let [rdr (doto (readers.ltn12-reader (ltn12.source.string "foo\nbar\r\nbaz"))
                (: :close))]
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read 3))
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read :*l))
      (assert-eq nil (rdr:peek 3))
      (assert-eq nil (rdr:read :*a)))))
