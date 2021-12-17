# Documentation
#' Visualise calibration
#' @description Use to obtain a calibration plot for a predictive model
#' @param predictr Output from the predictr function (alternative to fit parameter)
#' @param fit Logistic regression fit object (alternative to predictr parameter)
#' @param risk_ntile Numerical value specifying the number of predictive risk quantiles (default=NULL)
#' @param risk_class Numerical list specifying the cutoffs for predictive risk classes (default=NULL; range: 0 to 1)
#' @param se Logical value specifying if confidence intervals should be added to the plot
#' @return ggplot of the calibration plot with predicted risk either continuous (default) or categoried by quantiles or risk classes.
#' @import tibble
#' @import stringr
#' @import dplyr
#' @import tidyr
#' @importFrom finalfit glmmulti
#' @importFrom generalhoslem logitgof
#' @export

# Function:

cal_plot <- function(predictr = NULL, fit = NULL, risk_ntile = NULL, risk_class = NULL, se = F){

  if(is.null(predictr)==F){
    data <- predictr %>%
      dplyr::select(event, predict_prop)}

  if(is.null(fit)==F&is.null(predictr)==T){
    var_dep <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[1]
    var_exp <- stringr::str_split_fixed(fit$formula, " ~ ", 2)[2] %>% stringr::str_split("\\+") %>% unlist()

    data <- fit$data %>%
      dplyr::select(all_of(c(var_dep, var_exp))) %>%
      tidyr::drop_na() %>%
      dplyr::mutate(predict_prop = predict(fit, type = "response", newdata = .),
                    predict_raw = predict(fit, newdata = .)) %>%
      dplyr::select("event" = var_dep, predict_prop)}


  if(is.null(risk_ntile)&is.null(risk_class)){

    out <- data %>%
      dplyr::mutate(event = as.numeric(event)-1) %>%
      ggplot() +
      aes(x = predict_prop, y = event) +
      geom_jitter(height = 0.01, show.legend = F, alpha = 0.2, na.rm = T) +
      geom_smooth(method = "loess", se = se, show.legend = F, formula = 'y ~ x',
                  method.args=loess.control(statistics = "approximate", trace.hat = "approximate")) +
      geom_abline(linetype = "dashed") +
      scale_x_continuous(name = "Predicted Probability", limits = c(0, NA), expand = c(0,0)) +
      scale_y_continuous(name = "Observed Event", limits = c(-0.01, 1.01),
                         breaks = c(0,1), labels = levels(pull(data, event))) +
      theme_bw()}

  if(is.null(risk_ntile)==F){

    ntile_data <- cal_table(predictr = predictr, fit = fit, risk_ntile = risk_ntile)$ntile

    out <- ntile_data %>%
      dplyr::mutate(ntile_label = paste0(ntile, "\n(", format(round(pred_min, 3), nsmall = 3), " to ",
                                         format(round(pred_max, 3), nsmall = 3), ")"),
                    ntile_label = factor(ntile_label, levels = unique(ntile_label))) %>%
      dplyr::group_by(ntile) %>%
      dplyr::mutate(binom::binom.wilson(x = event, n = n, methods = "wilson") %>%
                      dplyr::select(lower, upper)) %>%
      dplyr::ungroup() %>%
      ggplot() +
      aes(x = ntile_label, y = prop) +
      geom_col(colour = "light blue", fill = "light blue") +
      geom_point(size = 4) +
      geom_linerange(aes(ymin = lower, ymax = upper), size = 2) +
      geom_smooth(aes(group=1), method = "lm", se= se, color = "blue", size = 1, formula = 'y ~ x') +
      scale_x_discrete(name = "Predicted Event Rate by Risk Group") +
      scale_y_continuous(name = "Proportion of Observed Events") +
      theme_bw()}

  if(is.null(risk_ntile)==T&is.null(risk_class)==F){
    class_data <- cal_table(predictr = predictr, fit = fit, risk_class = risk_class)$class

    levels(class_data$class) <- levels(class_data$class) %>%
      stringr::str_remove_all("\\(|\\]") %>%
      stringr::str_replace_all(",", " to ")

    out <- class_data %>%
      dplyr::group_by(class) %>%
      dplyr::mutate(binom::binom.wilson(x = event, n = n, methods = "wilson") %>%
                      dplyr::select(lower, upper)) %>%
      dplyr::ungroup() %>%
      ggplot() +
      aes(x = class, y = prop) +
      geom_col(colour = "light blue", fill = "light blue") +
      geom_point(size = 4) +
      geom_linerange(aes(ymin = lower, ymax = upper), size = 2) +
      geom_smooth(aes(group=1), method = "lm", se= se, color = "blue", size = 1, formula = 'y ~ x') +
      scale_x_discrete(name = "Predicted Event Rate by Risk Class") +
      scale_y_continuous(name = "Proportion of Observed Events") +
      theme_bw()}

  return(out)}
