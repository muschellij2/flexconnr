context("Trying to make sure normalize works")

test_that({
  testthat::skip_on_cran()
  if (reticulate::py_available()) {
    reticulate::use_python("python3")
    if (reticulate::py_numpy_available()) {
      flair = system.file("extdata", "FLAIR.nii.gz", package = "flexconnr")
      norm_flair = flexconn_normalize_image(flair, "FLAIR")
    }
  }
})
