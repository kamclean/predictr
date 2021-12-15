# Documentation
#' Plot TRIPOD data
#' @description  Plot TRIPOD data
#' @param data Output from tripod_format.
#' @return TRIPOD plot.
#' @import ggplot2
#' @export

tripod_plot <- function(data){
  data %>%
    ggplot()+
    aes(x = item, y = id) +
    geom_tile(aes(fill = value), colour = "black") +
    scale_fill_manual(name = "Reported", values = c("#C10000", "#E0E100","#00C100", "white")) +
    scale_colour_manual(name = "Reported", values = c("#C10000", "#E0E100","#00C100", "white")) +
    scale_x_discrete(name = "TRIPOD Reporting Guideline Item") +
    scale_y_discrete(name = NULL) +
    theme_bw(base_size = 12) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
          legend.position="bottom") +
    facet_grid(scales = "free_y", space = "free", rows =  vars(type))}
