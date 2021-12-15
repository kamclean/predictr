# Documentation
#' Obtain calibration metrics
#' @description Use to obtain calibration metrics for a predictive model
#' @param predictr Output from the predictr function (alternative to fit parameter)
#' @param fit Logistic regression fit object (alternative to predictr parameter)
#' @param hltest Logical value specifying if a Hosmer–Lemeshow test should be performed (default=FALSE)
#' @param risk_ntile Numerical value specifying the number of quantiles for the Hosmer–Lemeshow test (default=10)
#' @return Dataframe with the calibration slope and intecept (+/- Hosmer–Lemeshow test)
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom finalfit glmmulti
#' @importFrom generalhoslem logitgof
#' @export

# Function:

cal_metric <- function(predictr = NULL, fit = NULL, hltest  = F, risk_ntile = 10){


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

  fit_intercept <- finalfit::glmmulti(data, dependent = "event", explanatory = 1, offset = data$predict_raw)
  fit_slope <- finalfit::glmmulti(data, dependent = "event", explanatory = "predict_raw")

  metric <- tibble::tibble("intercept" = fit_intercept$coefficients,
                           "slope" = fit_slope$coefficients[2]) %>%
    dplyr::mutate(intercept = format(round(intercept,3), nsmall = 3),
                  slope = format(round(slope, 3), nsmall = 3))
  hl <- NULL
  if(hltest==T){
    hl <- generalhoslem::logitgof(obs = data$event, exp  =data$predict_prop, g=risk_ntile)$p.value %>%
      tibble::enframe(name = NULL, value = "hl") %>%
      dplyr::mutate(hl = format(round(hl,3), nsmall = 3)) %>%
      dplyr::pull(hl)

    metric <- metric %>% mutate(hl = hl)}

  return(metric)}
