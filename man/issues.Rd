% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data-issues.R
\docType{data}
\name{issues}
\alias{issues}
\title{Issue data for the dplyr repo from github API}
\format{JSON}
\usage{
issues
}
\description{
Issue data for the dplyr repo from github API
}
\examples{

library(dplyr)

# issues is a long character string
nchar(issues)

# Let's make it a tbl_json object
issues \%>\% as.tbl_json

# It begins as an array, so let's gather that
issues \%>\% gather_array

# Now let's spread all the top level values
issues \%>\% gather_array \%>\% spread_all \%>\% glimpse

# Are there any top level objects or arrays?
issues \%>\% gather_array \%>\% gather_object \%>\% json_types \%>\%
  count(name, type) \%>\%
  filter(type \%in\% c("array", "object"))

# Count issues labels by name
labels <- issues \%>\%
  gather_array \%>\%                    # stack issues as "issue.num"
  spread_values(id = jnumber(id)) \%>\% # capture just issue id
  enter_object(labels) \%>\%            # filter just those with labels
  gather_array("label.index") \%>\%     # stack labels
  spread_all
labels \%>\% glimpse

# Count number of distinct issues each label appears in
labels \%>\%
  group_by(name) \%>\%
  summarize(num.issues = n_distinct(id))
}
