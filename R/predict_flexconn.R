
#' Predict from FLEXCONN model
#'
#' @param t1 T1-weighted image to predict from: skullstripped, bias-corrected).
#' Since the training is 2D, make sure
#' the test image is properly oriented, i.e. the in-plane has the highest native
#' resolution. E.g. the training images are axial because their
#' native resolution is 1x1x4mm^3 in axial RAI orientation.
#' @param flair FLAIR image to predict from,
#' must be registered to T1 and have same orientation as T1
#' @param t2 (optional) T2 image to predict from,
#' must be registered to T1 and have same orientation as T1
#' @param outdir Output directory for predictions
#' @param gpu Either an integer for the GPU.
#' Use "cpu" to use CPU.
#' @param num_atlases Specifies which model to use.
#' Determined by the number of atlases in the FLEXCONN model.
#' @param outcomes The outcome used to train the model, from rater 1
#' or rater 2
#' @param normalize Should the images be normalized?
#' @param verbose Print diagnostic messages
#'
#' @return A vector of filenames
#' @export
#'
#' @importFrom reticulate use_python source_python
#' @importFrom neurobase checkimg nii.stub
#' @examples
#' # predict_flexconn(python_cmd = "python3)
#' library(reticulate)
#' \dontrun{
#' reticulate::use_python("/Library/Frameworks/Python.framework/Versions/3.5/bin/python3")
#' # reticulate::use_python("python3")
#'
#' flair = system.file("extdata", "FLAIR.nii.gz", package = "flexconnr")
#' t1 = system.file("extdata", "T1.nii.gz", package = "flexconnr")
#' pp = predict_flexconn(t1 = t1, flair = flair)
#' # result = RNifti::readNifti(pp[2])
#' }
#'
predict_flexconn = function(
  t1, flair, t2 = NULL,
  outdir = NULL,
  gpu = "cpu",
  normalize = TRUE,
  num_atlases = c("21", "61"),
  outcomes = c("mask1", "mask2"),
  verbose = TRUE) {

  py_predict_flexconn = NULL
  rm(list = "py_predict_flexconn")

  num_atlases = as.character(num_atlases)
  num_atlases = match.arg(num_atlases)
  if (num_atlases == "61" & !is.null(t2)) {
    warning(paste0("61 atlas model not available with T2! ",
                   "Using T1 and FLAIR only"))
    t2 = NULL
  }

  fname = "FLEXCONN_Test.py"
  if (!is.null(t2)) {
    fname = "FLEXCONN_Test_T2.py"
  }

  test_py = system.file("extdata", fname, package = "flexconnr")
  stopifnot(file.exists(test_py))
  # env = new.env()
  # reticulate::source_python(test_py, envir = env)
  reticulate::source_python(test_py)

  t1 = checkimg(t1)
  base = nii.stub(t1, bn = TRUE)

  flair = neurobase::checkimg(flair)

  if (is.null(outdir)) {
    outdir = tempfile()
  }

  outdir = path.expand(outdir)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  models = get_model_paths(
    num_atlases = num_atlases,
    outcomes = outcomes)
  models = c(models)
  stopifnot(length(models) > 0)
  # need for only length 1
  models = as.list(models)
  outfiles =  paste0(base,
                     c("_LesionMembership.nii.gz", "_LesionMask.nii.gz"))
  outfiles = file.path(outdir, outfiles)
  if (verbose) {
    message(paste0("Output files should be located at:\n ",
                   paste(outfiles, collapse = " and ")))
  }


  res = py_predict_flexconn(t1, flair, models, outdir, gpu,
                            normalize = normalize)
  if (!all(file.exists(outfiles))) {
    warning("Output files do not exist!")
  }
  attr(outfiles, "result") = res
  return(outfiles)
}
