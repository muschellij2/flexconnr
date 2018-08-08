
#' Training for Fast Lesion Extraction using Convolutional Neural Networks (FLEXCONN)
#'
#' @param patch_size Patch size, e.g. 35x35 or 31x31 (2D).
#' Patch sizes are separated by x.
#' Note that 2D patches are employed because usually FLAIR images are acquired 2D.
#' @param outdir Output directory where the trained models are written.
#' @param gpu Choice for GPU. Use the integer ID for the GPU.
#' Use "cpu" to use CPU.  Can also be \code{NULL}.
#' @param verbose Print diagnostic messages
#' @param atlas_dir Atlas directory containing atlasXX_T1.nii,
#' atlasXX_FL.nii.gz, atlasXX_mask.nii.gz, where \code{XX=1,2,3, etc}
#' All atlas images must be in axial RAI orientation, or whatever orientation
#' FLAIR has the highest in-plane resolution.  Atlas T1 and FLAIR images must
#' be coregistered and have same dimensions.Z
#'
#' @return A vector of filenames
#' @export
#'
#' @importFrom reticulate use_python source_python
#' @importFrom neurobase checkimg nii.stub
#' @examples
#' \dontrun{
#' library(reticulate)
#' use_python("python3")
#' }
#'
train_flexconn = function(
  atlas_dir,
  patch_size = c(35, 35),
  outdir = NULL,
  gpu = "gpu",
  verbose = TRUE) {

  atlas_dir = normalizePath(atlas_dir, winslash = "/", mustWork = TRUE)

  flair = list.files(atlas_dir, pattern = "atlas.*_FL.nii")
  t1 = list.files(atlas_dir, pattern = "atlas.*_T1.nii")
  mask = list.files(atlas_dir, pattern = "atlas.*_mask.nii")


  # worst check ever
  n_flair = length(flair)
  n_t1 = length(t1)
  n_mask = length(mask)
  n_atlas = max(n_flair, n_t1, n_mask)
  f = function(x, name) {
    if (length(x) != n_atlas) {
      msg = paste0(name, " has different number of atlases than required (",
                   n_atlas, ")")
      stop(msg)
    }
  }
  mapply(f, list(flair, t1, mask), c("flair", "t1", "mask"))


  #############################
  # Load the script
  #############################
  flexconn_dir = system.file("extdata", package = "flexconnr")
  stopifnot(dir.exists(flexconn_dir))

  train_py = file.path(flexconn_dir,
                      "FLEXCONN_Train.py")
  reticulate::source_python(train_py)

  if (is.null(outdir)) {
    outdir = tempfile()
  }

  stopifnot(length(patch_size) == 2)
  patch_size = paste(patch_size, collapse = "x")

  outdir = path.expand(outdir)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  out_stub = paste0("FLEXCONNmodel2D_", patch_size, "_")
  before_model = list.files(pattern = out_stub, path = outdir, recursive = FALSE,
                            full.names = TRUE)

  if (verbose) {
    message(paste0("Models should be in output directory with stub",
                   out_stub))
  }

  res = flexconn_train(
    atlas_dir = atlas_dir,
    numatlas = n_atlas,
    patchsize = patch_size,
    out_dir = outdir,
    gpu = gpu)

  after_model = list.files(pattern = out_stub, path = outdir, recursive = FALSE,
                            full.names = TRUE)
  outfiles = setdiff(after_model, before_model)

  return(outfiles)
}
