# Documentation
#' Extract coefficents from a logistic regression object
#' @description Use to extract coefficents from a logistic regression object
#' @param fit Logistic regression fit object
#' @param coefficient String of column name in df which represents the end date.
#' @return Tibble of labelled coefficents
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom finalfit summary_factorlist
#' @export

# Function:

coefficient <- function(fit, coefficient = "beta"){
  var_dep <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[1]

  coeff <- tibble::enframe(fit$coefficients,
                           name = "variable",
                           value = "value") %>%
    dplyr::mutate(outcome = var_dep,
                  coefficient = coefficient,
                  variable = ifelse(variable =="(Intercept)", "intercept", variable))

  var_exp <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[2] %>% stringr::str_split("\\+") %>% unlist()

  data <- fit$data %>%
    dplyr::select(all_of(c(var_dep, var_exp))) %>%
    tidyr::drop_na()

  intercept = coeff %>%
    dplyr::filter(variable=="intercept") %>%
    dplyr::mutate(label = "intercept",
                  levels = NA,
                  type = NA,
                  value = value,
                  outcome = var_dep,
                  coefficient = coefficient) %>%
    dplyr::select(label, levels, type, value, coefficient, outcome)


  out <- data %>%
    dplyr::mutate("group" = factor(1)) %>%
    finalfit::summary_factorlist(dependent = "group", explanatory = var_exp, fit_id=T) %>%
    dplyr::left_join(coeff, by = c("fit_id" = "variable")) %>%
    dplyr::mutate(value = ifelse(is.na(value)==T, 0, value),
                  label = ifelse(label=="", NA, label)) %>%
    tidyr::fill(label, outcome, coefficient, .direction = "down") %>%
    dplyr::mutate(type = ifelse(levels=="Mean (SD)", "numeric", "factor"),
                  levels = ifelse(levels=="Mean (SD)", NA, levels)) %>%
    dplyr::select(label, levels, type, value, coefficient, outcome) %>%
    tibble::as_tibble() %>%
    dplyr::bind_rows(intercept) %>%
    dplyr::mutate(value = ifelse(coefficient=="or", exp(value), value))

  return(out)}
