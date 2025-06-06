test_that("expect_valid_log fails when log file is nonsense", {
  # use a file name that "looks like" it could be a real Inspect log so that
  # Inspect tries to read it
  tmp_dir <- withr::local_tempdir()
  tmp_file <- file.path(
    tmp_dir,
    "2025-04-02T16-49-36-05-00_simpleaddition_e1e56aeef83a77f6392787.json"
  )
  file.create(tmp_file)
  writeLines(c("beep", "bop", "boop"), tmp_file)

  expect_error(
    suppressWarnings(expect_valid_log(tmp_file)),
    regexp = "Expecting value: line 1 column 1"
  )
})

test_that("vitals writes valid eval logs (basic, openai)", {
  skip_if(identical(Sys.getenv("OPENAI_API_KEY"), ""))
  tmp_dir <- withr::local_tempdir()
  withr::local_envvar(list(VITALS_LOG_DIR = tmp_dir))
  withr::local_options(cli.default_handler = function(...) {
  })
  local_mocked_bindings(interactive = function(...) FALSE)

  simple_addition <- tibble::tibble(
    input = c("What's 2+2?", "What's 2+3?"),
    target = c("4", "5")
  )

  tsk <- Task$new(
    dataset = simple_addition,
    solver = generate(ellmer::chat_openai(model = "gpt-4.1-nano")),
    scorer = model_graded_qa()
  )
  tsk$eval()
  expect_valid_log(tsk$log())
})

test_that("vitals writes valid eval logs (basic, claude)", {
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  tmp_dir <- withr::local_tempdir()
  withr::local_envvar(list(VITALS_LOG_DIR = tmp_dir))
  withr::local_options(cli.default_handler = function(...) {
  })
  local_mocked_bindings(interactive = function(...) FALSE)

  simple_addition <- tibble::tibble(
    input = c("What's 2+2?", "What's 2+3?"),
    target = c("4", "5")
  )

  tsk <- Task$new(
    dataset = simple_addition,
    solver = generate(ellmer::chat_anthropic(
      model = "claude-3-7-sonnet-latest"
    )),
    scorer = model_graded_qa()
  )
  tsk$eval()
  expect_valid_log(tsk$log())
})

test_that("vitals writes valid eval logs (basic, gemini)", {
  skip_if(identical(Sys.getenv("GOOGLE_API_KEY"), ""))
  tmp_dir <- withr::local_tempdir()
  withr::local_envvar(list(VITALS_LOG_DIR = tmp_dir))
  withr::local_options(cli.default_handler = function(...) {
  })
  local_mocked_bindings(interactive = function(...) FALSE)

  simple_addition <- tibble::tibble(
    input = c("What's 2+2?", "What's 2+3?"),
    target = c("4", "5")
  )

  tsk <- Task$new(
    dataset = simple_addition,
    solver = generate(ellmer::chat_google_gemini(model = "gemini-2.0-flash")),
    scorer = model_graded_qa()
  )
  tsk$eval()
  expect_valid_log(tsk$log())
})


test_that("vitals writes valid eval logs (solver tool calls, claude)", {
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  tmp_dir <- withr::local_tempdir()
  withr::local_envvar(list(VITALS_LOG_DIR = tmp_dir))
  withr::local_options(cli.default_handler = function(...) {
  })
  local_mocked_bindings(interactive = function(...) FALSE)
  library(ellmer)

  current_date <- tibble::tibble(
    input = c("What's the current date?"),
    target = c("2024-01-01")
  )

  ch <- chat_anthropic(model = "claude-3-7-sonnet-latest")
  ch$register_tool(tool(function() "2024-01-01", "Return the current date"))

  tsk <- Task$new(
    dataset = current_date,
    solver = generate(ch),
    scorer = function(samples) {
      list(score = factor("C", levels = c("I", "C"), ordered = TRUE))
    }
  )
  tsk$eval()
  expect_valid_log(tsk$log())
})

test_that("vitals writes valid eval logs (solver errors on tool call, claude)", {
  skip_if(identical(Sys.getenv("ANTHROPIC_API_KEY"), ""))
  tmp_dir <- withr::local_tempdir()
  withr::local_envvar(list(VITALS_LOG_DIR = tmp_dir))
  withr::local_options(cli.default_handler = function(...) {
  })
  local_mocked_bindings(interactive = function(...) FALSE)
  library(ellmer)

  current_date <- tibble::tibble(
    input = c("What's the current date?"),
    target = c("2024-01-01")
  )

  ch <- chat_anthropic(model = "claude-3-7-sonnet-latest")
  ch$register_tool(
    tool(function() stop("Couldn't find the date"), "Return the current date")
  )

  tsk <- Task$new(
    dataset = current_date,
    solver = generate(ch),
    scorer = function(samples) {
      list(score = factor("C", levels = c("I", "C"), ordered = TRUE))
    }
  )

  # a tool call will fail here and raise a warning; this is intentional.
  # since raised from ellmer, we don't expect anything specific about it.
  suppressWarnings(tsk$eval())

  log_file <- list.files(tmp_dir, full.names = TRUE)
  expect_gte(length(log_file), 1)

  expect_valid_log(log_file[1])
})

test_that("as_metadata can make lists into a named vector (#69)", {
  res <- as_metadata(mtcars[1:2, 1:2])
  expect_type(res, "list")
  expect_named(res, c("mpg", "cyl"))
  expect_snapshot(res)

  res <- as_metadata(tibble(x = list(list(a = 1, b = 2)), y = 3))
  expect_type(res, "list")
  expect_named(res, c("x", "y"))
  expect_snapshot(res)

  res <- as_metadata(list(1:3, b = 2))
  expect_type(res, "list")
  expect_named(res, c("1", "b"))
  expect_snapshot(res)

  res <- as_metadata(list(1:3, b = 2))
  expect_type(res, "list")
  expect_named(res, c("1", "b"))
  expect_snapshot(res)

  vec <- c(a = 1, b = 2)
  expect_equal(as_metadata(vec), as.list(vec))
})
