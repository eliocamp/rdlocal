# Language resolution against a module's `Language:` field. An exact match wins
# and is exclusive; otherwise fall back to the root language (split on "_"). This
# is what keeps zh_CN and zh_TW distinct while sharing the "zh" root.
rl <- rhelpi18n:::resolve_lang

assert("exact match wins and is exclusive (zh_CN vs zh_TW stay distinct)", {
  (identical(rl(c("zh_CN", "zh_TW"), "zh_CN"), c(TRUE,  FALSE)))
  (identical(rl(c("zh_CN", "zh_TW"), "zh_TW"), c(FALSE, TRUE)))
  (identical(rl(c("es", "en"), "es"), c(TRUE, FALSE)))
  # an exact hit suppresses the root-language fallback:
  (identical(rl(c("es_AR", "es_UY", "es"), "es_AR"), c(TRUE, FALSE, FALSE)))
})

assert("root-language fallback when there is no exact match", {
  (identical(rl(c("zh_CN", "zh_TW"), "zh"), c(TRUE, TRUE)))                # zh   -> both
  (identical(rl(c("es_UY", "es_ES", "es"), "es_AR"), c(TRUE, TRUE, TRUE))) # es_AR -> all es*
  (identical(rl(c("es_AR", "en"), "es"), c(TRUE, FALSE)))                  # es   -> es_AR
})

assert("no match returns all FALSE", {
  (identical(rl(c("fr", "de"), "es"), c(FALSE, FALSE)))
})

assert("a colon-separated LANGUAGE uses its first entry", {
  (identical(rl(c("en_AU", "es"), "en_AU:en"), c(TRUE, FALSE)))
})
