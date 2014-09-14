#' Commit data for the dplyr repo from github API
#' 
#' @docType data
#' @name commits
#' @usage commits
#' @format JSON
#' @examples
#' 
#' library(dplyr)
#' 
#' # Show first 2k characters of JSON
#' commits %>% substr(1, 2000) %>% writeLines
#' 
#' # Extract metadata for every commit
#' commits %>%   # single json document of github commits from dplyr 
#'   as.jdf %>%  # turn into a 'jdf'
#'   jarray %>%  # stack as an array
#'   jvalue(
#'     sha         = jstring("sha"),
#'     author      = jstring("commit", "author", "name"),
#'     author.date = jstring("commit", "author", "date")
#'   )
NULL