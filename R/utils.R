is_positron <- function() {
  Sys.getenv("POSITRON") == "1"
}

is_testing <- function() {
  identical(Sys.getenv("TESTTHAT"), "true")
}

# ad-hoc check functions
check_inherits <- function(x, cls, x_arg = caller_arg(x), call = caller_env()) {
  if (!inherits(x, cls)) {
    cli::cli_abort(
      "{.arg {x_arg}} must be a {.cls {cls}}, not {.obj_type_friendly {x}}",
      call = call
    )
  }

  invisible()
}

check_log_dir <- function(x, call = caller_env()) {
  if (is.na(x)) {
    cli::cli_warn(c(
      "!" = "{.pkg vitals} could not find a log directory; evaluation log
             files will be written to a temporary directory.",
      "i" = 'Set a log directory with e.g.
             {.code vitals::vitals_log_dir_set("./logs")}, 
             perhaps in {.file ~/.Rprofile}, to quiet this warning.'
    ))
  }
  invisible(x)
}

# miscellaneous ---------
solver_chat <- function(sample) {
  solver <- sample$solver_chat[[1]]
  res <- solver$clone()
  res$set_turns(list())
  res$set_system_prompt(NULL)
  res
}

interactive <- NULL

regenerate_example_objects <- function() {
  source("inst/regenerate-example-objects.R")
}

accuracy <- function(...) {
  mean(...) * 100
}
