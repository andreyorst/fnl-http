{:deps
 {"https://gitlab.com/andreyorst/async.fnl"
  {:type :git :sha "579934f1d735600f968b0633a6ea0b2a8f94816b"}
  "https://gitlab.com/andreyorst/json.fnl"
  {:type :git :sha "eebcb40750d6f41ed03fed04373f944dcf297383"}
  "https://gitlab.com/andreyorst/reader.fnl"
  {:type :git :sha "515c2695fad06d01f279c92d91e9e530a4a427e7"}
  "luasocket"
  {:type :rock :version "3.1.0-1"}}
 :paths
 {:fennel ["src/?.fnl" "src/?/init.fnl"]}
 :profiles
 {:dev
  {:deps {"https://gitlab.com/andreyorst/fennel-test"
          {:type :git :sha "416895275e4f20c1c00ba15dd0e274d1b459c533"}}
   :paths {:fennel ["tests/?.fnl"]}}}}
