# Documentation
#' Plot ROC plot for one or more models.
#' @description  Plot ROC plot for one or more models.
#' @param data Output from roc_plot_format
#' @param confint Logical value specifying if the confidence interval of the sensitivity/specificity should be displayed (must be same as in roc_plot_format)
#' @return ggplot ROC plot with one or more models displayed
#' @import tibble
#' @import ggplot2
#' @import dplyr
#' @import tidyr
#' @export

roc_plot <- function(data, confint = F){

  if(confint == TRUE & ("sen_lci" %in% names(data))==F){
    stop("Ensure roc_format(confint = T) to have CI output")}

  if(("model" %in% names(data))==F){data <- data %>% mutate(model = "1")}

  if(confint == F){
    plot <- data %>%
      dplyr::select(model, spe, starts_with("sen")) %>%
      dplyr::mutate(across(-contains("model"), function(x){as.numeric(x)})) %>%
      ggplot() +
      aes(x = 1-spe,group=model, colour=model) +
      geom_line(aes(y = sen_est)) +
      geom_abline(slope = 1, intercept = 0, linetype = 2, colour="black") +
      scale_x_continuous("1 - Specificity", limits = c(0, 1), expand = c(0,0)) +
      scale_y_continuous("Sensitivity", limits = c(0, 1), expand = c(0,0)) +
      scale_color_discrete(name = "Model") +
      theme_bw(base_size = 15)  + theme(legend.position = 'bottom')}


  if(confint == TRUE & ("sen_lci" %in% names(data))==T){
    plot <-  data %>%
      dplyr::select(model, spe, starts_with("sen")) %>%
      dplyr::mutate(across(-contains("model"), function(x){as.numeric(x)})) %>%
      ggplot() +
      aes(x = 1-spe,group=model, colour=model, fill = model) +
      geom_ribbon(aes(ymin = sen_lci, ymax = sen_uci, alpha=0.1), show.legend = F) +
      geom_line(aes(y = sen_est))  +
      geom_abline(slope = 1, intercept = 0, linetype = 2, colour="black") +
      scale_x_continuous("1 - Specificity", limits = c(0, 1), expand = c(0,0)) +
      scale_y_continuous("Sensitivity", limits = c(0, 1), expand = c(0,0)) +
      scale_fill_discrete(name ="Model") +
      theme_bw(base_size = 15)  + theme(legend.position = 'bottom')}

  return(plot)}
