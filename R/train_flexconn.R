
#' Training for Fast Lesion Extraction using Convolutional Neural Networks (FLEXCONN)
#'
#' @param patch_size Patch size, e.g. 35x35 or 31x31 (2D).
#' Patch sizes are separated by x.
#' Note that 2D patches are employed because usually FLAIR images are acquired 2D.
#' @param use_t2 should T2 images be used?
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
  use_t2 = FALSE,
  patch_size = c(35, 35),
  outdir = NULL,
  gpu = "gpu",
  verbose = TRUE) {

  flexconn_train = NULL
  rm(list = "flexconn_train")

  atlas_dir = normalizePath(atlas_dir, winslash = "/", mustWork = TRUE)

  flair = list.files(atlas_dir, pattern = "atlas.*_FL.nii")
  t1 = list.files(atlas_dir, pattern = "atlas.*_T1.nii")
  if (use_t2) {
    t2 = list.files(atlas_dir, pattern = "atlas.*_T2.nii")
  }
  mask = list.files(atlas_dir, pattern = "atlas.*_mask.nii")


  # worst check ever
  n_flair = length(flair)
  n_t1 = length(t1)
  n_t2 = 0
  if (use_t2) {
    n_t2 = length(t2)
  }
  n_mask = length(mask)
  n_atlas = max(n_flair, n_t1, n_mask, n_t2)
  f = function(x, name) {
    if (length(x) != n_atlas) {
      msg = paste0(name, " has different number of atlases than required (",
                   n_atlas, ")")
      stop(msg)
    }
  }
  L = list(flair = flair, t1 = t1, mask = mask)
  if (use_t2) {
    L$t2 = t2
  }
  mapply(f, L, names(L))


  #############################
  # Load the script
  #############################
  fname = ifelse(use_t2, "FLEXCONN_Train_T2.py", "FLEXCONN_Train.py")
  train_py = system.file("extdata", fname,
                         package = "flexconnr")
  stopifnot(file.exists(train_py))
  reticulate::source_python(train_py)

  if (is.null(outdir)) {
    outdir = tempfile()
  }

  stopifnot(length(patch_size) == 2)
  patch_size = paste(patch_size, collapse = "x")

  outdir = path.expand(outdir)
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

  out_stub = paste0("FLEXCONNmodel2D_", patch_size, "_")
  before_model = list.files(pattern = out_stub,
                            path = outdir,
                            recursive = FALSE,
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

  after_model = list.files(pattern = out_stub,
                           path = outdir, recursive = FALSE,
                           full.names = TRUE)
  outfiles = setdiff(after_model, before_model)

  return(outfiles)
}
