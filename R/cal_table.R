# Documentation
#' Table of calibration
#' @description Use to obtain a calibration table for a predictive model
#' @param predictr Output from the predictr function (alternative to fit parameter)
#' @param fit Logistic regression fit object (alternative to predictr parameter)
#' @param risk_ntile Numerical value specifying the number of predictive risk quantiles (default=10)
#' @param risk_class Numerical list specifying the cutoffs for predictive risk classes (default=NULL; range: 0 to 1)
#' @return Tibble of the number of events / sample per risk quantile or risk classes
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom purrr compact
#' @export

# Function:

cal_table <- function(predictr = NULL, fit = NULL, risk_ntile = 10, risk_class = NULL){

  if(is.null(predictr)==F){
   data <- predictr %>%
      dplyr::select(event, predict_prop, predict_raw)}

  if(is.null(fit)==F&is.null(predictr)==T){
    var_dep <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[1]
    var_exp <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[2] %>% stringr::str_split("\\+") %>% unlist()

    data <- fit$data %>%
      dplyr::select(all_of(c(var_dep, var_exp))) %>%
      tidyr::drop_na() %>%
      dplyr::mutate(predict_prop = predict(fit, type = "response", newdata = .),
                    predict_raw = predict(fit, newdata = .)) %>%
      dplyr::select("event" = var_dep, predict_prop, predict_raw)}


  ntile <- NULL
  if(is.null(risk_ntile)==F){
    if(is.numeric(risk_ntile)&risk_ntile>1){
      ntile <- data %>%
        dplyr::mutate(event = as.numeric(event)-1) %>%
        dplyr::select(event, predict_prop) %>%
        dplyr::mutate(ntile = ntile(predict_prop, risk_ntile) %>% factor()) %>%
        dplyr::group_by(ntile) %>%
        dplyr::summarise(n = n(),
                         event = sum(event==1),
                         prop = event / n,
                         pred_med = median(predict_prop),
                         pred_min = min(predict_prop),
                         pred_max = max(predict_prop))}}

  class <- NULL
  if(is.null(risk_class)==F){
    if(is.numeric(risk_class)&unique(risk_class>=0)==T&unique(risk_class<=1)==T){

      class_break = c(0, risk_class, 1) %>% unique() %>% as.numeric() %>% sort()
      class <- data %>%
        dplyr::mutate(event = as.numeric(event)-1) %>%
        dplyr::select(event, predict_prop) %>%
        dplyr::mutate(class = cut(predict_prop, breaks = class_break)) %>%
        dplyr::group_by(class) %>%
        dplyr::summarise(n = n(),
                         event = sum(event==1),
                         prop = event / n,
                         pred_med = median(predict_prop),
                         pred_min = min(predict_prop),
                         pred_max = max(predict_prop))}}

  return(purrr::compact(list("ntile" = ntile, "class" = class)))}
