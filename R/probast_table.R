# Documentation
#' Format PROBAST risk of bias data as a table
#' @description  Format PROBAST risk of bias data as a table
#' @param data Output from probast_format.
#' @return Tibble of PROBAST risk of bias data
#' @import tibble
#' @import dplyr
#' @import tidyr
#' @export

probast_table <- function(data){
  data %>%
    dplyr::filter(domain=="Risk of Bias") %>%
    dplyr::mutate(item = paste0(as.character(subdomain), " ", item)) %>%
    dplyr::select(-domain, -assess, -subdomain) %>%
    tidyr::pivot_wider(id_cols = c("id", "type"), names_from = "item", values_from = "value",
                       values_fn = list) %>%
    tidyr::unnest(cols = -all_of(c("id", "type")))}
