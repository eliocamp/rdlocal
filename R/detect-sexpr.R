# Detect install/build \Sexpr (and #ifdef) spans in a help topic and replace each
# with a {ISEXPR_i} placeholder, forming a translation *scaffold* whose static text
# is stable across installs. Dynamic nodes are found from the SOURCE parse tree
# (the parser balances multi-line / nested-brace code); their exact deparse
# (to_text) is located by fixed-string search in the flattened source; the matching
# gap in the flattened baked help is the dynamic value. Used by
# install_with_translation().

.def <- function(x, d) if (is.null(x)) d else x

# Collect non-render \Sexpr and #ifdef/#ifndef nodes (opaque dynamic spans), in
# document order. `marker` is the node's exact deparse (== how it appears in the
# flattened source). Dynamic nodes are opaque: we do not recurse into them.
.collect_sexpr_markers <- function(node, acc = list()) {
  tag <- attr(node, "Rd_tag")
  if (identical(tag, "\\Sexpr") &&
      !isTRUE(grepl("stage=render", .def(attr(node, "Rd_option"), "")))) {
    acc[[length(acc) + 1L]] <- list(
      marker = to_text(node), kind = "sexpr",
      option = .def(attr(node, "Rd_option"), ""),
      code   = trimws(paste(rapply(node, as.character, how = "unlist"), collapse = "")))
    return(acc)
  }
  if (!is.null(tag) && tag %in% c("#ifdef", "#ifndef")) {
    acc[[length(acc) + 1L]] <- list(
      marker = to_text(node), kind = "ifdef", option = tag,
      code   = trimws(paste(rapply(node, as.character, how = "unlist"), collapse = "")))
    return(acc)
  }
  if (is.list(node)) for (child in node) acc <- .collect_sexpr_markers(child, acc)
  acc
}

# Records whose deparse occurs in `src_o`, ordered by position in `src_o`.
.markers_in <- function(src_o, records) {
  hit <- Filter(function(r) grepl(r$marker, src_o, fixed = TRUE), records)
  if (length(hit) == 0) return(hit)
  pos <- vapply(hit, function(r) regexpr(r$marker, src_o, fixed = TRUE)[[1]], numeric(1))
  hit[order(pos)]
}

# Split `s` on a set of literal markers, returning the static anchors between.
.split_on <- function(s, markers) {
  anchors <- character(0)
  rest <- s
  for (mk in markers) {
    p <- regexpr(mk, rest, fixed = TRUE)
    if (p == -1) stop("marker not found while splitting source original")
    anchors <- c(anchors, substr(rest, 1, p - 1))
    rest <- substr(rest, p + nchar(mk), nchar(rest))
  }
  c(anchors, rest)
}

# Locate anchors sequentially in `inst_o`; the gaps between them are baked values.
.align_anchors <- function(anchors, inst_o) {
  n_spans <- length(anchors) - 1L
  baked <- character(n_spans)
  cur <- inst_o
  consume <- function(anchor, s) {
    if (nchar(anchor) == 0) return(list(before = "", rest = s))
    p <- regexpr(anchor, s, fixed = TRUE)
    if (p == -1) stop("anchor not found while aligning baked original")
    list(before = substr(s, 1, p - 1), rest = substr(s, p + nchar(anchor), nchar(s)))
  }
  step <- consume(anchors[1], cur); cur <- step$rest
  for (i in seq_len(n_spans)) {
    nxt <- consume(anchors[i + 1L], cur)
    baked[i] <- nxt$before
    cur <- nxt$rest
  }
  baked
}

# Build a scaffold for one flattened string pair (source vs baked).
.build_scaffold <- function(src_o, inst_o, records) {
  recs <- if (is.null(src_o)) list() else .markers_in(src_o, records)
  if (length(recs) == 0) {
    return(list(original = inst_o, scaffold = inst_o, spans = list()))
  }
  markers    <- vapply(recs, function(r) r$marker, character(1))
  anchors    <- .split_on(src_o, markers)
  baked_vals <- .align_anchors(anchors, inst_o)
  scaffold <- anchors[1]
  spans <- vector("list", length(recs))
  for (i in seq_along(recs)) {
    scaffold <- paste0(scaffold, "{ISEXPR_", i - 1L, "}", anchors[i + 1L])
    spans[[i]] <- list(i = i - 1L, kind = recs[[i]]$kind, option = recs[[i]]$option,
                       baked_value = baked_vals[i])
  }
  list(original = inst_o, scaffold = scaffold, spans = spans)
}

.is_simple   <- function(x) is.list(x) && is.character(x$original)
.is_itemlist <- function(x) is.list(x) && length(x) > 0 && all(vapply(x, .is_simple, logical(1)))

# Per-section scaffolds from a source + baked parsed Rd (\arguments -> per \item).
detect_scaffolds <- function(src_rd, baked_rd) {
  records   <- .collect_sexpr_markers(src_rd)
  src_flat  <- rd_flatten(src_rd)
  inst_flat <- rd_flatten(baked_rd)
  out <- list()
  for (sec in names(inst_flat)) {
    iel <- inst_flat[[sec]]; sel <- src_flat[[sec]]
    if (.is_simple(iel)) {
      out[[sec]] <- .build_scaffold(sel$original, iel$original, records)
    } else if (.is_itemlist(iel)) {
      items <- list()
      for (nm in names(iel)) {
        so <- if (!is.null(sel) && !is.null(sel[[nm]])) sel[[nm]]$original else NULL
        items[[nm]] <- .build_scaffold(so, iel[[nm]]$original, records)
      }
      out[[sec]] <- items
    }
  }
  out
}
