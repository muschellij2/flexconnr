context("Trying to make sure normalize works")

testthat::test_that(desc = "trying to normalize images", {
  testthat::skip_on_cran()
  if (reticulate::py_available()) {
    py_path = "/Library/Frameworks/Python.framework/Versions/3.5/bin/python3"
    if (!file.exists(py_path)) {
      py_path = "python"
    }
    reticulate::use_python(py_path)
    if (reticulate::py_numpy_available()) {
      flair = system.file("extdata", "FLAIR.nii.gz", package = "flexconnr")
      norm_flair = flexconnr::flexconn_normalize_image(flair, "FLAIR")
    }
  }
})
