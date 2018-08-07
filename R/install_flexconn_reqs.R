#' Install FLEXCONN requirements
#'
#' @param gpu Install GPU tensorflow
#' @param ... Additional arguments to pass to \code{\link{install_tensorflow}}
#'
#' @importFrom tensorflow tf_version install_tensorflow
install_flexconn_reqs = function(
  gpu = FALSE,
  ...
) {
  extra_packages = c("numpy",
                     "keras",
                     "scipy",
                     "statsmodels",
                     "tqdm",
                     "nibabel",
                     "h5py",
                     "scikit-learn",
                     paste0("tensorflow", ifelse(gpu, "-gpu", "")),
                     "termcolor")
  tensorflow::install_tensorflow(extra_packages = extra_packages, ...)
}
