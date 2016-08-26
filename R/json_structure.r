#' Recursively structures arbitrary JSON data into a single data.frame
#'
#' Returns a \code{tbl_json} object where each row corresponds to a leaf in
#' the JSON structure. The first row corresponds to the json document as
#' a whole. If the document is a scalar value (JSON string, number, logical
#' or null), then there will only be 1 row. If instead it is an object or
#' an array, then subsequent rows will recursively correspond to the elements
#' (and their children) of the object or array.
#'
#' @param x a json string or a tbl_json object
#' @return a tbl_json object with the following columns:
#'
#'   \code{document.id} 1L if \code{x} is a single JSON string, otherwise the
#'   index of \code{x}.
#'
#'   \code{parent.id} the string identifier of the parent node for this child.
#'
#'   \code{level} what level of the hierarchy this child resides at, starting
#'   at \code{0L} for the root and incrementing for each level of nested
#'   array or object.
#'
#'   \code{index} what index of the parent object / array this child resides
#'   at (from \code{gather_array} for arrays).
#'
#'   \code{child.id} a unique ID for this leaf in this document, represented
#'   as <parent>.<index> where <parent> is the ID for the parent and <index>
#'   is this index.
#'
#'   \code{seq} the sequence of keys / indices that led to this child
#'   (parents that are arrays are excluded) as a list, where character strings
#'   denote objects and integers denote array positions
#'
#'   \code{key} if this is the value of an object, what was the key that it
#'   is listed under (from \code{gather_keys}).
#'
#'   \code{type} the type of this object (from \code{json_types}).
#'
#'   \code{length} the length of this object (from \code{json_lengths}).
#'
#' @export
#' @examples
#' library(magrittr)  # for %>%
#'
#' # A simple string
#' '"string"' %>% json_structure
#'
#' # A simple object
#' '{"key": "value"}' %>% json_structure
#'
#' # A complex array
#' '[{"a": 1}, [1, 2], "a", 1, true, null]' %>% json_structure
json_structure <- function(x) {

  if (!is.tbl_json(x)) x <- as.tbl_json(x)

  # Create initial structure for top level
  structure <- json_structure_init(x)

  this_level <- 0L
  while(structure %>% should_json_structure_expand_more(this_level)) {

    structure <- rbind_tbl_json(
      structure,
      json_structure_level(structure %>% filter(level == this_level))
    )

    this_level <- this_level + 1L

  }

  structure

}

json_structure_init <- function(x) {

  x %>%
    mutate(
      parent.id = NA_character_,
      level = 0L,
      index = 1L,
      child.id = "1",
      seq = replicate(n(), list()),
      key = NA_character_
    ) %>%
    json_types %>%
    json_lengths

}

should_json_structure_expand_more <- function(s, this.level) {

  s %>%
    filter(level == this.level) %>%
    `[[`("type") %>%
    `%in%`(c("object", "array")) %>%
    any

}

json_structure_empty <- function() {

  tbl_json(
    data_frame(
      document.id = integer(0),
      parent.id = character(0),
      level = integer(0),
      index = integer(0),
      child.id = character(0),
      seq = list(),
      key = character(0),
      type = factor(character(0), levels = allowed_json_types),
      length = integer(0)
    ),
    list()
  )

}

json_structure_level <- function(s) {

  new_s <- json_structure_empty()

  # Expand any objects
  if (any(s$type == "object")) {
    new_s <- rbind_tbl_json(
      new_s,
      s %>% json_structure_objects
    )
  }

  # Expand any arrays
  if (any(s$type == "array")) {
    new_s <- rbind_tbl_json(
      new_s,
      s %>% json_structure_arrays
    )
  }

  new_s

}

json_structure_objects <- function(s) {

  expand_s <- s %>%
    filter(type == "object") %>%
    transmute(
      document.id,
      parent.id = child.id,
      seq,
      level = level + 1L
    ) %>%
    gather_keys %>%
    json_types %>%
    json_lengths

  # Create rest of data frame
  df_s <- expand_s %>%
    group_by(parent.id) %>%
    mutate(index = 1L:n()) %>%
    ungroup %>%
    mutate(
      child.id = paste(parent.id, index, sep = "."),
      seq = map2(seq, key, c)
    ) %>%
    select(
      document.id, parent.id, level, index, child.id, seq, key, type, length
    )

  # Reconstruct tbl_json object
  tbl_json(df_s, attr(expand_s, "JSON"))

}

json_structure_arrays <- function(s) {

  s %>%
    filter(type == "array") %>%
    transmute(
      document.id,
      parent.id = child.id,
      seq,
      level = level + 1L
    ) %>%
    gather_array("index") %>%
    json_types %>%
    json_lengths %>%
    mutate(
      child.id = paste(parent.id, index, sep = "."),
      seq = map2(seq, index, c)
    ) %>%
    transmute(
      document.id, parent.id, level, index, child.id,
      seq, key = NA_character_, type, length
    )

}

# Bind two tbl_json objects together and preserve JSON attribute
rbind_tbl_json <- function(x, y) {

  tbl_json(
    bind_rows(x, y),
    c(attr(x, "JSON"), attr(y, "JSON"))
  )

}
