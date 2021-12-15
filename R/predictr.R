# Documentation
#' Predict a binary event based on a model or coefficents
#' @description Predict a binary event based on a model or coefficents
#' @param data Tibble containing all coefficents / outcome of interest as specified in fit or coefficent parameters.
#' @param coefficient Output from the coefficent function (alternative to fit parameter)
#' @param fit Logistic regression fit object (alternative to coefficient parameter)
#' @return Tibble with 2 appended columns: "predict_raw" (the original output prediction) and "predict_prop" (the predicted probability of the event)
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom boot inv.logit
#' @export

# Function:

predictr <- function(data, coefficient = NULL, fit = NULL){
  if(is.null(fit)==F){
    var_exp <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[2] %>% stringr::str_split("\\+") %>% unlist()
    var_dep <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[1]

    out <- data %>%
      dplyr::select(all_of(c(var_dep, var_exp))) %>%
      tidyr::drop_na() %>%
      tibble::rowid_to_column() %>%
      dplyr::mutate(event  = pull(., var_dep),
                    predict_raw = predict(fit, newdata  = ., ),
                    predict_prop = predict(fit, type = "response", newdata  = ., ))}




  if(is.null(coefficient)==F&is.null(fit)==T){
    coefficient <- coefficient %>%
      dplyr::mutate(value = ifelse(coefficient %in% c("OR", "or"), log(value, base = exp(1)), value))

    var_dep <- unique(coefficient$outcome)

    var_num <- coefficient %>%
      dplyr::filter(type=="numeric") %>%
      dplyr::select(label, "beta" = value)

    data_num <- NULL
    if(nrow(var_num)>0){

      var_exp <- coefficient %>%
        dplyr::filter(label!="intercept") %>%
        pull(label) %>% unique()

      data <- data %>%
        dplyr::select(all_of(c(var_dep, var_exp))) %>%
        tidyr::drop_na() %>%
        tibble::rowid_to_column()

      data_num <- data %>%
        dplyr::select(rowid, all_of(var_num$label)) %>%
        tidyr::pivot_longer(cols = -rowid, names_to = "label", values_to = "original") %>%
        dplyr::left_join(var_num,by = "label") %>%
        dplyr::mutate(predict = beta * original,
                      original = as.character(original)) %>%
        dplyr::select(rowid, label, "value" = original, predict)}

    var_fct <- coefficient %>%
      dplyr::filter(type=="factor") %>%
      dplyr::select(label, levels, "predict" = value)

    data_fct <- NULL
    if(nrow(var_fct)>0){

      data_fct <- data %>%
        dplyr::select(rowid, all_of(var_fct$label)) %>%
        tidyr::pivot_longer(cols = -rowid, names_to = "label", values_to = "levels") %>%
        dplyr::left_join(var_fct, by = c("label", "levels")) %>%
        dplyr::select(rowid, label, "value" = levels, predict)}

    long <- bind_rows(data_num, data_fct) %>%
      tidyr::pivot_wider(id_cols = "rowid", names_from = "label", values_from = "predict") %>%
      dplyr::mutate(intercept = coefficient %>% filter(label=="intercept") %>% pull(value)) %>%
      dplyr::mutate(predict_raw = rowSums(dplyr::select(.,-rowid)),
                    predict_prop = boot::inv.logit(predict_raw)) %>%
      dplyr::select(predict_raw, predict_prop)

    out <- bind_cols(data, long) %>%
      dplyr::mutate(event  = pull(., var_dep)) %>%
      dplyr::select(all_of(names(data)), event, predict_raw, predict_prop)}

  return(out)}
