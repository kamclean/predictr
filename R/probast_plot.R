# Documentation
#' Plot PROBAST data
#' @description  Plot PROBAST data
#' @param data Output from probast_table.
#' @return PROBAST plot.
#' @import ggplot2
#' @export

probast_plot <- function(data){

  data %>%
    ggplot()+
    aes(x = subdomain, y = id) +
    geom_point(aes(colour = assess, fill = assess), size = 5) +
    # geom_text(aes(x = subdomain, label = sign),colour = "black", size = 5, fontface = "bold") +
    geom_vline(xintercept = 1.5, show.legend = F, colour = "dark grey", linetype = "dashed") +
    scale_fill_manual(name = "Assessment", values = c("#C10000", "#E0E100", "#00C100")) +
    scale_colour_manual(name = "Assessment", values = c("#C10000", "#E0E100", "#00C100")) +
    scale_x_discrete(name = "PROBAST Assessment") +
    scale_y_discrete(name = NULL) +
    theme_bw(base_size = 12) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
          legend.position="bottom") +
    facet_grid(type ~ domain, scales = "free", space = "free")}
