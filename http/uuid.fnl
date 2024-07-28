(local m/mod
  (or math.fmod math.mod))

(local {:floor m/floor
        :random m/random}
  math)

(local {:sub s/sub
        :format s/format}
  string)

(fn num->bs [num]
  (var (result num) (values "" num))
  (if (= num 0) 0
      (do (while (> num 0)
            (set result (.. (m/mod num 2) result))
            (set num (m/floor (* num 0.5))))
          result)))

(fn bs->num [num]
  (if (= num :0) 0
      (do (var (index result) (values 0 0))
          (for [p (length (tostring num)) 1 -1]
            (local this-val (s/sub num p p))
            (when (= this-val :1)
              (set result (+ result (^ 2 index))))
            (set index (+ index 1)))
          result)))

(fn padbits [num bits]
  (if (= (length (tostring num)) bits)
      num
      (do (var num num)
          (for [i 1 (- bits (length (tostring num)))]
            (set num (.. :0 num)))
          num)))

(fn random-uuid []
  "Generates a random UUIDv4 value."
  (m/random)
  (let [time-low-a (m/random 0 65535)
        time-low-b (m/random 0 65535)
        time-mid (m/random 0 65535)
        time-hi (padbits (num->bs (m/random 0 4095)) 12)
        time-hi-and-version (bs->num (.. :0100 time-hi))
        clock-seq-hi-res (.. :10 (padbits (num->bs (m/random 0 63)) 6))
        clock-seq-low (padbits (num->bs (m/random 0 255)) 8)
        clock-seq (bs->num (.. clock-seq-hi-res clock-seq-low))
        node {1 nil 2 nil 3 nil 4 nil 5 nil 6 nil}]
    (for [i 1 6]
      (tset node i (m/random 0 255)))
    (var guid "")
    (doto guid
      (set (.. guid (padbits (s/format "%x" time-low-a) 4)))
      (set (.. guid (padbits (s/format "%x" time-low-b) 4) "-"))
      (set (.. guid (padbits (s/format "%x" time-mid) 4) "-"))
      (set (.. guid (padbits (s/format "%x" time-hi-and-version) 4) "-"))
      (set (.. guid (padbits (s/format "%x" clock-seq) 4) "-")))
    (for [i 1 6]
      (set guid (.. guid (padbits (s/format "%x" (. node i)) 2))))
    guid))

{: random-uuid}
