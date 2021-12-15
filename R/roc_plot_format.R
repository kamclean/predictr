# Documentation
#' Format data prior to plotting ROC plot for one or more models.
#' @description  Format data prior to plotting ROC plots for one or more models.
#' @param data Dataframe with at least 2 columns: (1) binary outcome of interest, (2) predicted probability of outcome (binary or continuous)
#' @param model Optional string specifying the column name specifying which model each outcome/prediction belongs to (default ="model"). This allows multiple models to be assessed within 1 function.
#' @param event String specifying the column name containing the binary outcome of interest (default ="event")
#' @param predict String specifying the column name containing predicted probability of outcome (default ="prediction")
#' @param smooth Logical value specifying if the ROC curve should be smoothed (default=TRUE)
#' @param confint Logical value specifying if the confidence interval of the sensitivity/specificity should be calculated.
#' @return Tibble with sensitivity/specificity for one or more models.
#' @import tibble
#' @import dplyr
#' @import tidyr
#' @importFrom pROC roc ci.se smooth coords
#' @importFrom purrr map_df
#' @export

roc_plot_format <- function(data, model = NULL, event = "event", predict = "predict", smooth = TRUE, confint = TRUE){

  if(is.null(model)==T){data <- data %>% mutate(model = "1")}

  clean <- data %>%
    dplyr::mutate(model = dplyr::pull(., model),
                  response = dplyr::pull(., event) %>% factor(),
                  predictor = dplyr::pull(., predict) %>% as.numeric()) %>%
    tidyr::drop_na() %>%
    dplyr::select(model, response, predictor)

  output <- clean %>%
    dplyr::group_split(model) %>%
    purrr::map_df(function(x){
      roc <- x %>%
        pROC::roc(response = "response", # actual data on your outcome
                  predictor = "predictor",  #  what your model predicts your outcome will be
                  ci=confint, levels = levels(clean$response), direction=c("<"))

      if(confint==T){
        roc_out <- roc %>%
          pROC::ci.se(specificities=seq(0, 1, .01)) %>%
          as.data.frame() %>%
          tibble::rownames_to_column(var = "spe") %>%
          tibble::as_tibble() %>%
          dplyr::mutate(model = unique(x$model)) %>%
          dplyr::select(model, spe, sen_est = `50%`,
                        sen_lci = `2.5%`, sen_uci = `97.5%`)}

      if(confint==F){
        roc_out <- x %>%
          pROC::roc(response = "response", # actual data on your outcome
                    predictor = "predictor",  #  what your model predicts your outcome will be
                    ci=confint, levels = levels(clean$response), direction=c("<"))

        if(smooth==T){roc_out <- roc_out %>% pROC::smooth()}

        roc_out <- roc_out %>%
          pROC::coords() %>%
          tibble::as_tibble() %>%
          dplyr::mutate(model = unique(x$model)) %>%
          dplyr::select(model, spe = specificity, sen_est = sensitivity)}

      if(is.null(model)==T){roc_out <- roc_out %>% dplyr::select(-model)}
      return(roc_out)})

  return(output)}
