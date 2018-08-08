#' Normalize Image
#'
#' @param image Object of class \code{nifti} or filename
#' @param contrast Type of imaging modality.
#'
#' @return An list of object of class \code{nifti} and the peak used to norm.
#' @export
#'
#' @importFrom neurobase check_nifti
#' @importFrom reticulate import
#' @examples
#' \dontrun{
#' library(reticulate)
#' use_python("/Library/Frameworks/Python.framework/Versions/3.5/bin/python3")
#'
#' flair = system.file("extdata", "FLAIR.nii.gz", package = "flexconnr")
#' norm_flair = flexconn_normalize_image(flair, "FLAIR")
#' }
flexconn_normalize_image = function(
  image, contrast = c("T1", "T2", "FLAIR", "PD")) {

  ximage = check_nifti(image)

  contrast = match.arg(contrast)
  contrast = substr(contrast, 1, 2)

  image = checkimg(image)

  flexconn_dir = system.file("extdata", package = "flexconnr")
  stopifnot(dir.exists(flexconn_dir))
  nb = import("nibabel", convert = FALSE)
  np = import("numpy", convert = FALSE)
  image = nb$load(image)
  image = image$get_data()
  image = image$astype(np$float32)

  test_py = file.path(flexconn_dir,
                      "normalize_image.py")
  reticulate::source_python(test_py)
  peak = normalize_image(image, contrast = contrast)

  peak = as.numeric(c(peak))
  ximage = ximage / peak
  L = list(
    image = ximage,
    norm_image = ximage,
    peak = peak)
  return(ximage)
}
