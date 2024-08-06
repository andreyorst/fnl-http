(comment
 "MIT License

  Copyright (c) 2021 Andrey Listopadov

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the “Software”), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.")

;;; Macros

(eval-compiler
  (local lib-name (or ... "fennel-test"))

  (fn string-len [s]
    (if (and _G.utf8 _G.utf8.len)
        (_G.utf8.len s)
        (length s)))

  (fn assert-eq [expr1 expr2 msg]
    "Like `assert', except compares results of `expr1' and `expr2' for equality.
Generates formatted message if `msg' is not set to other message.

# Example
Compare two expressions:

``` fennel :skip-test
(assert-eq 1 (+ 1 2))
;; => runtime error: equality assertion failed
;; =>   Left: 1
;; =>   Right: 3
```

Deep compare values:

``` fennel :skip-test
(assert-eq [1 {[2 3] [4 5 6]}] [1 {[2 3] [4 5]}])
;; => runtime error: equality assertion failed
;; =>   Left:  [1 {[2 3] [4 5 6]}]
;; =>   Right: [1 {[2 3] [4 5]}]
```"
    (let [s1 (view expr1 {:one-line? true})
          s2 (view expr2 {:one-line? true})
          formatted (if (> (string-len (.. "(eq )" s1 s2)) 80)
                        (string.format "(eq %s\n    %s)" s1 s2)
                        (string.format "(eq %s %s)" s1 s2))]
      `(let [{:eq eq#} (require ,lib-name)
             tostring# (match (pcall require :fennel)
                         (true fennel#) #(fennel#.view $ {:one-line? true})
                         false tostring)
             (lok# left#) ,(if (. (get-scope) :vararg)
                               `(pcall (fn [...] ,expr1) ...)
                               `(pcall (fn [] ,expr1)))
             (rok# right#) ,(if (. (get-scope) :vararg)
                                `(pcall (fn [...] ,expr2) ...)
                                `(pcall (fn [] ,expr2)))]
         (if (not lok#)
             (error (: "in expression:\n%s\n%s\n" :format ,s1 (tostring# left#)))
             (not rok#)
             (error (: "in expression:\n%s\n%s\n" :format ,s2 (tostring# right#)))
             (assert (eq# left# right#)
                     (string.format
                      "assertion failed for expression:\n%s\n Left: %s\nRight: %s\n%s"
                      ,formatted
                      (tostring# left#)
                      (tostring# right#)
                      ,(if msg `(.. " Info: " (tostring# ,msg)) ""))))
         nil)))

  (fn assert-ne
    [expr1 expr2 msg]
    "Assert for unequality.  Like `assert', except compares results of
`expr1' and `expr2' for unequality.  Generates formatted message if
`msg' is not set to other message.  Same as `assert-eq'."
    (let [s1 (view expr1 {:one-line? true})
          s2 (view expr2 {:one-line? true})
          formatted (if (> (string-len (.. "(not (eq ))" s1 s2)) 80)
                        (string.format "(not (eq %s\n         %s))" s1 s2)
                        (string.format "(not (eq %s %s))" s1 s2))]
      `(let [{:eq eq#} (require ,lib-name)
             tostring# (match (pcall require :fennel)
                         (true fennel#) #(fennel#.view $ {:one-line? true})
                         false tostring)
             (lok# left#) ,(if (. (get-scope) :vararg)
                               `(pcall (fn [...] ,expr1) ...)
                               `(pcall (fn [] ,expr1)))
             (rok# right#) ,(if (. (get-scope) :vararg)
                                `(pcall (fn [...] ,expr2) ...)
                                `(pcall (fn [] ,expr2)))]
         (if (not lok#)
             (error (: "in expression:\n%s\n%s\n" :format ,s1 (tostring# left#)))
             (not rok#)
             (error (: "in expression:\n%s\n%s\n" :format ,s2 (tostring# right#)))
             (assert (not (eq# left# right#))
                     (string.format
                      "assertion failed for expression:\n%s\n Left: %s\nRight: %s\n%s"
                      ,formatted
                      (tostring# left#)
                      (tostring# right#)
                      ,(if msg `(.. " Info: " (tostring# ,msg)) ""))))
         nil)))

  (fn assert-is
    [expr msg]
    "Assert `expr' for truth. Same as inbuilt `assert', except generates more
  verbose message unless the `msg` is provided.

``` fennel :skip-test
(assert-is (= 1 2 3))
;; => runtime error: assertion failed for (= 1 2 3)
```"
    `(let [tostring# (match (pcall require :fennel)
                       (true fennel#) #(fennel#.view $ {:one-line? true})
                       false tostring)
           (suc# res#) ,(if (. (get-scope) :vararg)
                            `(pcall (fn [...] ,expr) ...)
                            `(pcall (fn [] ,expr)))]
       (if suc#
           (do (assert res# (string.format
                             "assertion failed for expression:\n%s\nResult: %s\n%s"
                             ,(view expr {:one-line? true})
                             (tostring res#)
                             ,(if msg `(.. "  Info: " (tostring# ,msg)) "")))
               nil)
           (error (string.format
                   "in expression: %s: %s\n"
                   ,(view expr {:one-line? true})
                   res#)))))

  (fn assert-not
    [expr msg]
    "Assert `expr' for not truth. Generates more verbose message unless the
`msg` is provided.  Works the same as `assert-is'."
    `(let [tostring# (match (pcall require :fennel)
                       (true fennel#) #(fennel#.view $ {:one-line? true})
                       false tostring)
           (suc# res#) ,(if (. (get-scope) :vararg)
                            `(pcall (fn [...] ,expr) ...)
                            `(pcall (fn [] ,expr)))]
       (if suc#
           (do (assert (not res#)
                       (string.format
                        "assertion failed for expression:\n(not %s)\nResult: %s\n%s"
                        ,(view expr {:one-line? true})
                        (tostring res#)
                        ,(if msg `(.. "  Info: " (tostring# ,msg)) "")))
               nil)
           (error (string.format
                   "in expression: (not %s): %s\n"
                   ,(view expr {:one-line? true})
                   res#)))))

  (fn deftest
    [name ...]
    "Simple way of grouping tests with `name'.

# Example
``` fennel :skip-test
(deftest some-test
  ;; tests
  )
```
"
    `(let [(_# test-ns#) ...]
       (fn ,name []
         ,...)
       (if (= :table (type test-ns#))
           (table.insert test-ns# [,(tostring name) ,name])
           (,name))))

  (fn testing
    [description ...]
    "Simply wraps the test code with a `description`.

# Example
``` fennel :skip-test
(testing \"testing something\"
  ;; test body
  )
```
"
    (assert-compile (= :string (type description))
                    "description must be a string"
                    description)
    `(do ,...))

  (fn use-fixtures [fixture-type ...]
    "Wrap test runs in a `fixture` function to perform setup and
teardown.  Using a `fixture-type` of `:each` wraps every test
individually, while `:once` wraps the whole run in a single function.
Multiple `fixtures` and fixture-types are supported in one form.

Firstures are active only when the thests are being run by the
`run-test' function.

# Example

``` fennel :skip-test
(use-fixtures
 :once
 (fn [test]
   (setup1) (test) (teardown1))
 (fn [test]
   (setup2) (test) (teardown2))
 :each
 (fn [test]
   (setup3) (test) (teardown3)))
```
"
    {:fnl/arglist [fixture-type fixture & fixtures]}
    (assert-compile (or (= fixture-type :once) (= fixture-type :each))
                    "Expected :once or :each as the first argument"
                    fixture-type)
    `(let [(ns# _# fixtures#) ...]
       (var fixture-type# ,fixture-type)
       (when (= :table (type fixtures#))
         (each [_# fixture# (ipairs ,[...])]
           (if (or (= fixture# :each) (= fixture# :once))
               (set fixture-type# fixture#)
               (do
                 (when (not (. fixtures# fixture-type# ns#))
                   (tset fixtures# fixture-type# ns# []))
                 (tset fixtures# fixture-type# ns#
                       (+ 1 (length (. fixtures# fixture-type# ns#)))
                       fixture#)))))))

  (tset macro-loaded lib-name
        {: deftest
         : testing
         : assert-eq
         : assert-ne
         : assert-is
         : assert-not
         : use-fixtures}))

;;; Equality

(fn eq [...]
  "Comparison function.

Accepts arbitrary amount of values, and does the deep comparison.  If
values implement `__eq` metamethod, tries to use it, by checking if
first value is equal to second value, and the second value is equal to
the first value.  If values are not equal and are tables does the deep
comparison.  Tables as keys are supported."
  (match (select "#" ...)
    0 true
    1 true
    2 (let [(a b) ...]
        (if (and (= a b) (= b a))
            true
            (= :table (type a) (type b))
            (do (var (res count-a) (values true 0))
                (each [k v (pairs a) :until (not res)]
                  (set res (eq v (do (var (res done) (values nil nil))
                                     (each [k* v (pairs b) :until done]
                                       (when (eq k* k)
                                         (set (res done) (values v true))))
                                     res)))
                  (set count-a (+ count-a 1)))
                (when res
                  (let [count-b (accumulate [res 0 _ _ (pairs b)]
                                  (+ res 1))]
                    (set res (= count-a count-b))))
                res)
            false))
    _ (let [(a b) ...]
        (and (eq a b) (eq (select 2 ...))))))

;;; Test Runner
;;;; Reporters

(local dots
  {:ns-start #(do (_G.io.stdout:write "(") (_G.io.stdout:flush))
   :ns-report #(do (_G.io.stdout:write ")") (_G.io.stdout:flush))
   :test-start #nil
   :test-report (fn [ok? test-name msg]
                  (_G.io.stdout:write (if ok? "." "F"))
                  (_G.io.stdout:flush))
   :stats-report (fn [warnings errors]
                   (_G.io.stdout:write "\n")
                   (each [_ message (ipairs warnings)]
                     (_G.io.stderr:write "Warning: " message "\n"))
                   (each [_ {: ns : test-name : message : stdout : stderr} (ipairs errors)]
                     (_G.io.stderr:write
                      "Error in '" ns
                      "' in test '" test-name "':\n"
                      message "\n")
                     (when (not= "" stdout)
                       (_G.io.stderr:write
                        "Test stdout:\n"
                        stdout))
                     (when (not= "" stderr)
                       (_G.io.stderr:write
                        "Test stderr:\n"
                        stderr))))})

(local namespaces
  {:ns-start (fn [ns]
               (_G.io.stdout:write ns ": ")
               (_G.io.stdout:flush))
   :ns-report (fn [ns ok?] (_G.io.stdout:write (if ok? "PASS" "FAIL") "\n"))
   :test-start #nil
   :test-report #nil
   :stats-report (fn [warnings errors]
                   (each [_ message (ipairs warnings)]
                     (_G.io.stderr:write "Warning: " message "\n"))
                   (each [_ {: ns : test-name : message : stdout : stderr} (ipairs errors)]
                     (_G.io.stderr:write
                      "Error in '" ns
                      "' in test '" test-name "':\n"
                      message "\n")
                     (when (not= "" stdout)
                       (_G.io.stderr:write
                        "Test stdout:\n"
                        stdout))
                     (when (not= "" stderr)
                       (_G.io.stderr:write
                        "Test stderr:\n"
                        stderr))))})

;;;; Configuration

(fn file-exists? [file]
  {:private true}
  (let [fh (_G.io.open file)]
    (when fh (fh:close))
    (not= fh nil)))

(fn setup-runner [config]
  {:private true}
  (let [{: dofile : view} (require config.fennel-lib)
        config (if (file-exists? ".fennel-test")
                   (collect [k v (pairs (dofile :.fennel-test))
                             :into config]
                     k v)
                   config)]
    (if (= config.reporter :dots)
        (set config.reporter dots)
        (= config.reporter :namespaces)
        (set config.reporter namespaces)
        (and (= :table (type config.reporter))
             (= :function (type config.reporter.ns-start))
             (= :function (type config.reporter.ns-report))
             (= :function (type config.reporter.test-start))
             (= :function (type config.reporter.test-report))
             (= :function (type config.reporter.stats-report)))
        nil
        (not= nil config.reporter)
        (do (_G.io.stderr:write
             "Warning: unknown or malformed reporter: "
             (view config.reporter)
             "\nUsing default reporter: dots\n")
            (set config.reporter dots)))
    (math.randomseed config.seed)
    config))

;;;; Utils

(fn join [sep ...]
  ;; Concatenate multiple values into a string using `sep` as a
  ;; separator.
  {:private true}
  (table.concat
   (fcollect [i 1 (select :# ...)]
     (tostring (select i ...))) sep))

(local unpack (or table.unpack _G.unpack))

(fn with-no-output [out err fn1 ...]
  "Redirects output from stdout and stderr to `out` and `err` tables."
  {:private true}
  (let [{:write io/write :read io/read
         : stdin : stdout : stderr} _G.io
        {:write fd/write :read fd/read &as fd}
        (. (getmetatable _G.io.stdin) :__index)
        lua-print print
        pack #(doto [$...] (tset :n (select "#" $...)))
        args (pack ...)]
    (fn fd.write [fd ...]
      (if (or (= fd stdout) (= fd stderr))
          (table.insert (if (= fd stdout) out err) (join "" ...))
          (fd/write fd ...))
      fd)
    (fn _G.print [...]
      (_G.io.write (.. (join "\t" ...) "\n"))
      nil)
    (fn _G.io.write [...]
      (: (_G.io.output) :write ...))
    (let [(_ res) (pcall #(pack (fn1 (unpack args 1 args.n))))]
      (set _G.print lua-print)
      (set _G.io.wirte io/write)
      (set fd.write fd/write)
      (unpack res 1 res.n))))

;;;; Test loading

(fn load-tests [modules config tests fixtures]
  {:private true}
  (let [{: make-searcher : view} (require config.fennel-lib)
        searcher (make-searcher
                  (collect [k v (pairs (or config.searcher-opts {}))
                            :into {:correlate true}]
                    k v))]
    (each [_ module-name (ipairs modules)]
      (let [module-tests []
            fn1 (searcher module-name)]
        (if (= :function (type fn1))
            (do (fn1 module-name module-tests fixtures)
                (table.insert tests [module-name module-tests]))
            (error fn1 2))))))

(fn shuffle-table [t]
  {:private true}
  (for [i (length t) 2 -1]
    (let [j (math.random i)
          ti (. t i)]
      (tset t i (. t j))
      (tset t j ti))))

(fn shuffle-tests [tests]
  {:private true}
  (each [_ [_ test-ns] (ipairs tests)]
    (shuffle-table test-ns))
  (shuffle-table tests))

;;;; Fixtures

(fn default-fixture [f]
  {:private true}
  (f))

(fn compose-fixtures [f1 f2]
  {:private true}
  (fn [g] (f1 (fn [] (f2 g)))))

(fn join-fixtures [fixtures]
  {:private true}
  (accumulate [f default-fixture _ fixture (ipairs fixtures)]
    (compose-fixtures f fixture)))

(fn setup-fixtures [once-each fixtures]
  {:private true}
  (each [ns fs (pairs (. fixtures once-each))]
    (tset fixtures once-each ns (join-fixtures fs))))

;;;; Runner

(fn run-ns-tests [ns tests config fixtures warnings errors]
  {:private true}
  (let [{: reporter} config
        oncef (or (. fixtures.once ns) default-fixture)]
    (var ok? true)
    (reporter.ns-start ns)
    (oncef
     (fn []
       (let [eachf (or (. fixtures.each ns) default-fixture)]
         (if (= 0 (length tests))
             (table.insert warnings (: "namespace '%s' has no tests" :format ns))
             (each [test-n [test-name test-fn] (ipairs tests)]
               (reporter.test-start ns test-name test-n (length tests))
               (let [err [] out []]
                 (match (if config.capture-output?
                            (with-no-output out err #(pcall eachf test-fn))
                            (pcall eachf test-fn))
                   (false msg) (do (set ok? false)
                                   (reporter.test-report
                                    false ns test-name msg)
                                   (table.insert errors {: ns : test-name :message msg
                                                         :stdout (table.concat out "")
                                                         :stderr (table.concat err "")}))
                   _ (reporter.test-report true ns test-name))))))))
    (reporter.ns-report ns ok?)))

(fn merge [t1 t2]
  (if (and (= :table (type t1)) (= :table (type t2)))
      (collect [k v (pairs t2) :into t1]
        k v)
      t1))

(fn run-tests [modules opts]
  "Run tests in the given `modules`.
Each module is loaded and inspected for tests defined with the
`deftest' macro.  Then, according to the configuration file
`.fennel-test`, the tests are shuffled, ran, and report is constructed
by the reporter specified in the config.

The `modules` argument is a sequential table of module names relative
to the script that runs the tests.

If the test module sets up fixtures with the `use-fixtures'
macro. these fixtures are used accordingly to their specs.

# Example

``` fennel :skip-tests
(run-tests [:tests.fixture-test :tests.equality-test])
```"
  (let [tests []
        fixtures {:once {} :each {}}
        errors []
        warnings []
        config
        (setup-runner
         (merge {:seed
                 (tonumber
                  (or (_G.os.getenv "FENNEL_TEST_SEED")
                      (math.floor (* 1000 (+ (_G.os.time) (_G.os.clock))))))
                 :reporter :dots
                 :capture-output? true
                 :fennel-lib :fennel
                 :shuffle? true
                 :exit? false}
                opts))]
    (_G.io.stdout:write
     "Test run at " (_G.os.date) ", seed: " config.seed "\n")
    (load-tests modules config tests fixtures)
    (setup-fixtures :once fixtures)
    (setup-fixtures :each fixtures)
    (when config.shuffle?
      (shuffle-tests tests))
    (each [_ [ns tests] (ipairs tests)]
      (run-ns-tests ns tests config fixtures warnings errors))
    (config.reporter.stats-report warnings errors)
    (when (next errors)
      (_G.os.exit 1))))

{: eq : run-tests}
