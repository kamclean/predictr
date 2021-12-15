# Documentation
#' Derive diagnostic/prognostic accuracy metrics for one or more models.
#' @description Derive diagnostic/prognostic accuracy metrics for one or more models.
#' @param data Dataframe with at least 2 columns: (1) binary outcome of interest, (2) predicted probability of outcome (binary or continuous)
#' @param model Optional string specifying the column name specifying which model each outcome/prediction belongs to (default ="model"). This allows multiple models to be assessed within 1 function.
#' @param event String specifying the column name containing the binary outcome of interest (default ="event")
#' @param predict String specifying the column name containing predicted probability of outcome (default ="prediction")
#' @return Tibble with relevant diagnostic/prognostic accuracy metrics for one or more models.
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom reportROC reportROC
#' @importFrom epiR epi.tests
#' @export

roc_metric <- function(data, model = NULL, event = "event", predict = "prediction"){

  if(is.null(model)==T){data <- data %>% mutate(model = "1")}

  clean <- data %>%
    dplyr::mutate(model = dplyr::pull(., model),
                  response = dplyr::pull(., event) %>% factor(),
                  predictor = dplyr::pull(., predict)) %>%
    dplyr::select(model, response, predictor) %>%
    tidyr::drop_na()


  pred_num <- NULL; pred_bin <- NULL

  bin1_tf <- length(unique(dplyr::pull(data, predict)))==2&(is.numeric(dplyr::pull(data, predict))==F)
  bin2_tf <- unique(unique(dplyr::pull(data, predict))[1:2]== c(0,1))
  num1_tf <- length(unique(dplyr::pull(data, predict)))>2|is.numeric(dplyr::pull(data, predict))

  if(bin1_tf==T|bin1_tf==T){pred_bin = dplyr::pull(data, predict)}
  if(num1_tf==T){pred_num = dplyr::pull(data, predict)}

  if(is.null(pred_num)==F){

    out <-  clean %>%
      dplyr::group_split(model) %>%
      purrr::map_df(function(x){
        reportROC::reportROC(gold = dplyr::pull(x, response),
                             predictor = dplyr::pull(x, predictor), plot=F,
                             positive = "l") %>%
          tibble::tibble() %>%
          tidyr::pivot_longer(cols= everything()) %>%
          dplyr::mutate(type = stringr::str_split_fixed(name, "\\.", 2)[,2],
                        name = stringr::str_split_fixed(name, "\\.", 2)[,1]) %>%
          dplyr::filter(! name %in% c("P", "ACC")) %>%
          dplyr::filter(! type %in% c("SE")) %>%
          dplyr::mutate(type = ifelse(type=="", "estimate", type)) %>%
          tidyr::pivot_wider(id_cols = "name", names_from = "type", values_from = "value") %>%
          dplyr::select(name, estimate, "lci"=low, "uci" = up) %>%
          dplyr::mutate_at(vars(-name), as.numeric) %>%
          dplyr::mutate(metric = paste0(format(round(estimate, 3), digits=3),
                                        " (95% CI: ",
                                        format(round(lci, 3), digits=3), " to ",
                                        format(round(uci, 3), digits=3), ")")) %>%
          dplyr::mutate(metric = stringr::str_remove(metric, " \\(95% CI:    NA to    NA\\)"),
                        name = case_when(name=="Curoff" ~ "Cutoff",
                                         name=="AUC" ~ "AUC",
                                         name=="SEN" ~ "Sensitivity",
                                         name=="SPE" ~ "Specificity",
                                         name=="PLR" ~ "Positive Likelihood Ratio",
                                         name=="NLR" ~ "Negative Likelihood Ratio",
                                         name=="PPV" ~ "Positive Predictive Value (PPV)",
                                         name=="NPV" ~ "Negative Predictive Value (NPV)",
                                         TRUE ~ name))%>%
          dplyr::mutate(name = factor(name, levels = unique(name))) %>%
          dplyr::mutate(model = unique(x$model)) %>%
          dplyr::select(model, everything())})}

  if(is.null(pred_bin)==F){
    out <- clean %>%
      dplyr::group_split(model) %>%
      purrr::map_df(function(x){

    result <- x %>%
      dplyr::select(all_of(c(original, predictor))) %>%
      dplyr::mutate(across(everything(), forcats::fct_rev)) %>%
      table() %>%
      epiR::epi.tests()

    tibble::enframe(result$elements) %>%
      dplyr::filter(name %in% c("aprev", "tprev", "diag.acc", "sensitivity",  "specificity",  "pv.positive",
                                "pv.negative", "lr.positive",  "lr.negative")) %>%
      dplyr::mutate(name = factor(name,
                                  levels = c("aprev", "tprev", "diag.acc", "sensitivity",  "specificity",  "lr.positive",  "lr.negative",  "pv.positive","pv.negative"),
                                  labels = c("Predicted Prevalence", "True Prevalence", "Diagnostic Accuracy", "Sensitivity", "Specificity",
                                             "Positive Likelihood Ratio", "Negative Likelihood Ratio",
                                             "Positive Predictive Value", "Negative Predictive Value"))) %>%
      dplyr::arrange(name) %>%
      dplyr::mutate(abbr = c("", "", "", "SEN", "SPE", "PLR", "NLR", "PPV", "NPV")) %>%
      dplyr::select(name, abbr, value) %>%
      tidyr::unnest(cols = "value") %>%
      dplyr::rename("estimate" = est, "lci" = lower, "uci" = upper) %>%
      dplyr::mutate(metric = paste0(format(round(estimate, 3), digits=3),
                                    " (95% CI: ",
                                    format(round(lci, 3), digits=3), " to ",
                                    format(round(uci, 3), digits=3), ")"))})}

  return(out)}
