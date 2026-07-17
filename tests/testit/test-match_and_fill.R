# Tests for the runtime placeholder matcher. Strings only, no translation module.
mf <- rhelpi18n:::match_and_fill

assert("no-token: exact match and drift fallback", {
  (mf("abc", "abc", "xyz")$text == "xyz")
  (mf("abd", "abc", "xyz")$text == "abd")
})

assert("single-token fill (start / end / empty / multiline / regex-literal)", {
  (mf("on Monday", "on {ISEXPR_0}", "el {ISEXPR_0}")$text == "el Monday")
  (mf("Xyz", "{ISEXPR_0}yz", "{ISEXPR_0}ZZ")$text == "XZZ")
  (mf("ab7", "ab{ISEXPR_0}", "cd{ISEXPR_0}")$text == "cd7")
  (mf("ab", "a{ISEXPR_0}b", "x{ISEXPR_0}y")$text == "xy")
  (mf("a\nL1\nL2\nb", "a{ISEXPR_0}b", "x{ISEXPR_0}y")$text == "x\nL1\nL2\ny")
  (mf("id=[a-z]+$", "id={ISEXPR_0}", "id={ISEXPR_0}")$text == "id=[a-z]+$")
})

assert("multiple and adjacent tokens", {
  (mf("a1b2c", "a{ISEXPR_0}b{ISEXPR_1}c", "A{ISEXPR_0}B{ISEXPR_1}C")$text == "A1B2C")
  (mf("xVALy", "x{ISEXPR_0}{ISEXPR_1}y", "p{ISEXPR_0}{ISEXPR_1}q")$text == "pVALq")
})

assert("scaffold roundtrip: same scaffold as translation reproduces the live", {
  (mf("Installed on Monday.", "Installed on {ISEXPR_0}.", "Installed on {ISEXPR_0}.")$text ==
     "Installed on Monday.")
})

assert("no-match and NULL inputs fall back to live", {
  (mf("zzz", "a{ISEXPR_0}c", "A{ISEXPR_0}C")$text == "zzz")
  (mf("a?c", "a{ISEXPR_0}b{ISEXPR_1}c", "A{ISEXPR_0}B{ISEXPR_1}C")$text == "a?c")
  (mf("aXYd", "a{ISEXPR_0}c", "A{ISEXPR_0}C")$text == "aXYd")
  (mf("abc", NULL, "xyz")$text == "abc")
  (mf("abc", "abc", NULL)$text == "abc")
})

assert("#ifdef: active branch translated, inactive marker kept", {
  (mf("pre SHOWN post", "pre {ISEXPR_0} post", "PRE {ISEXPR_0} POST",
      list("0" = "ES"))$text == "PRE ES POST")
  (mf("pre #ifdef windows not active post", "pre {ISEXPR_0} post", "PRE {ISEXPR_0} POST",
      list("0" = "ES"))$text == "PRE #ifdef windows not active POST")
})

assert("literal {{ISEXPR_n}} escaping", {
  (mf("a {ISEXPR_0} b", "a {{ISEXPR_0}} b", "c {{ISEXPR_0}} d")$text == "c {ISEXPR_0} d")
  (mf("v=VAL lit={ISEXPR_9}", "v={ISEXPR_0} lit={{ISEXPR_9}}",
      "x={ISEXPR_0} y={{ISEXPR_9}}")$text == "x=VAL y={ISEXPR_9}")
})

assert("reason and distance metadata", {
  (mf("on Monday", "on {ISEXPR_0}", "el {ISEXPR_0}")$reason == "valid")
  (mf("on Monday", "on {ISEXPR_0}", "el {ISEXPR_0}")$distance == 0)
  (mf("put at Tuesday", "put on {ISEXPR_0}", "puesto {ISEXPR_0}")$reason == "stale")
  (mf("put at Tuesday", "put on {ISEXPR_0}", "puesto {ISEXPR_0}")$distance > 0)
  (mf("on Monday", "on {ISEXPR_0}", NULL)$reason == "untranslated")
  (is.infinite(mf("on Monday", "on {ISEXPR_0}", NULL)$distance))
})
