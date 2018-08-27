#' Getting Model Paths for trained models
#'
#' @param num_atlases Specifies which model to use.
#' Determined by the number of atlases in the FLEXCONN model.
#' @param outcomes The outcome used to train the model, from rater 1
#' or rater 2
#'
#' @return A matrix of filenames
#' @export
#'
#' @examples
#' get_model_paths()
#' get_model_paths(num_atlases = "21")
#' get_model_paths(outcomes = "mask1")
#' get_model_paths(num_atlases = "21", outcomes = "mask1")
get_model_paths = function(
  num_atlases = c("21", "61"),
  outcomes = c("mask1", "mask2")
  ) {
  num_atlases = as.character(num_atlases)
  num_atlases = match.arg(num_atlases, several.ok = TRUE)

  outcomes = match.arg(outcomes, several.ok = TRUE)
  flexconn_dir = system.file("extdata", package = "flexconnr")

  models = file.path(
    flexconn_dir,
    paste0(num_atlases, "atlases"))
  names(models) = num_atlases
  models = sapply(
    models,
    function(path) {
      pat = paste(outcomes, collapse = "|")
      res = list.files(pattern = ".*.h5$", path = path,
                 full.names = TRUE, recursive = TRUE)
      res = res[ grepl(pat, res)]
      res
    }
  )
  models = unlist(models)
  models = as.matrix(models)
  rownames(models) = sub(".*atlas_with_(.*)/FLEX.*", "\\1", models[,1])
  # models = unname(models)
  return(models)
}
