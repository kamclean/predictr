# Documentation
#' Format PROBAST data prior to plotting
#' @description  Format PROBAST data prior to plotting
#' @param data PROBAST data in format as specified in  "example_probast.csv".
#' @param id  String specifying the column name containing the identifier for the specific paper/model.
#' @param type String specifying the column name containing the type of model ("d"=derivation, "dv" = "derivation and validation", "v" = validation)
#' @return Tibble of PROBAST data formatted for a PROBAST plot / table
#' @import tibble
#' @import dplyr
#' @import tidyr
#' @export
probast_format(readRDS("~/predictr/data/example_probast.rds"), id = "score") %>%
  probast_plot()
# Function:
probast_format <- function(data, id = "id", type = "type"){

  # Clean-----------------
  rob = c("rob_1_1", "rob_1_2", "rob_2_1", "rob_2_2", "rob_2_3", "rob_3_1", "rob_3_2",
          "rob_3_3", "rob_3_4", "rob_3_5", "rob_3_6", "rob_4_1", "rob_4_2", "rob_4_3",
          "rob_4_4", "rob_4_5", "rob_4_6", "rob_4_7", "rob_4_8", "rob_4_9")
  app = c("app_1", "app_2", "app_3")

  columns <- c("id", "type", rob, app)

  data <- data %>%
    dplyr::mutate(id = pull(., id),
                  type = pull(., type)) %>%
    dplyr::select(id, type, starts_with("rob_"), starts_with("app_")) %>%
    dplyr::select(all_of(columns))

  # Check only 5 types
  check_type <- data %>% dplyr::filter(! type %in% c("d", "dvi", "dve", "dvie", "ve"))
  if(nrow(check_type)>0){stop(paste0("Please ensure all studies have one of 5 types assigned: d, dvi, dve, dvie, ve"))}

  long <-   suppressWarnings(data %>%
                               dplyr::mutate(across(everything(), function(x){as.character(x)})) %>%
                               tidyr::pivot_longer(cols = -all_of(c("id", "type")), names_to = "name") %>%
                               tidyr::separate(col = "name", into = c("domain", "subdomain", "item"),sep  ="_")) %>%

    dplyr::mutate(item = factor(as.numeric(item)),
                  subdomain = factor(subdomain, levels = c("5", "1","2", "3", "4"),
                                     labels = c( "Overall","Participants", "Predictors", "Outcome", "Analysis")),
                  domain = factor(domain, levels = c("rob", "app"), labels = c("Risk of Bias", "Applicability")),
                  type = factor(type, levels = c("d", "dvi", "dve", "dvie", "ve"),
                                labels = c("Derivation",
                                           "Derivation +\nValidation (Internal)",
                                           "Derivation +\nValidation (External)",
                                           "Derivation +\nValidation (Both)",
                                           "Validation\n(External)")))

   data_rob <- long %>%
    dplyr::filter(domain == "Risk of Bias") %>%

    # Filter for items relevant for specific study design
    dplyr::filter(! (type=="Validation (External)"&subdomain=="Analysis"&item %in% c("5", "8", "9"))) %>%

    dplyr::mutate(value = tolower(value),
                  value = case_when(value %in% c("y", "yes", "yes (y)") ~ "Y",
                                    value %in% c("py", "probably yes", "probably yes (py)") ~ "PY",
                                    value %in% c("ni", "no information", "no information (ni)") ~ "NI",
                                    value %in% c("pn", "probably no", "probably no (pn)") ~ "PN",
                                    value %in% c("n", "no", "no (n)") ~ "N")) %>%
    dplyr::group_by(id, type, domain, subdomain) %>%
    dplyr::mutate(n_y = sum(value %in% c("Y", "PY")),
                  n_n = sum(value %in% c("N", "PN")),
                  n_ni = sum(value %in% c("NI")),
                  assess = case_when(n_y>0&n_n==0&n_ni==0 ~ "Low",
                                     n_y>=0&n_n==0&n_ni>0 ~ "Unclear",
                                     n_y>=0&n_n>0&n_ni>=0 ~ "High"),
                  assess = factor(assess, levels = c("High", "Unclear", "Low"))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-starts_with("n_"))

  data_rob_overall <- data_rob %>%
    dplyr::distinct(id,type, domain, subdomain, assess) %>%
    dplyr::group_by(id,type, domain) %>%
    dplyr::summarise(n_low = sum(assess=="Low", na.rm = T),
                  n_high = sum(assess=="High", na.rm = T),
                  n_unclear = sum(assess=="Unclear", na.rm = T),
                  assess = case_when(n_low>0&n_high==0&n_unclear==0 ~ "Low",
                                      n_low>=0&n_high==0&n_unclear>0 ~ "Unclear",
                                      n_low>=0&n_high>0&n_unclear>=0 ~ "High",
                                      TRUE ~ NA_character_),
                  .groups = "drop") %>%
    dplyr::mutate(subdomain = factor("Overall", levels = levels(data_rob$subdomain))) %>%
    dplyr::select(-starts_with("n_"))

  data_app <- long %>%
    filter(domain == "Applicability") %>%
    dplyr::mutate(value = tolower(value),
                  value = case_when(value %in% c("low", "l") ~ "Low",
                                    value %in% c("high", "high") ~ "High",
                                    value %in% c("unclear", "u") ~ "Unclear"),
                  assess = factor(value, levels = c("High", "Unclear", "Low")))



  data_app_overall <- data_app %>%
    dplyr::distinct(id,type, domain, subdomain, assess) %>%
    dplyr::group_by(id,type, domain) %>%
    dplyr::summarise(n_low = sum(assess=="Low", na.rm = T),
                     n_high = sum(assess=="High", na.rm = T),
                     n_unclear = sum(assess=="Unclear", na.rm = T),
                     assess = case_when(n_low>0&n_high==0&n_unclear==0 ~ "Low",
                                        n_low>=0&n_high==0&n_unclear>0 ~ "Unclear",
                                        n_low>=0&n_high>0&n_unclear>=0 ~ "High",
                                        TRUE ~ NA_character_),
                     .groups = "drop") %>%
    dplyr::mutate(subdomain = factor("Overall", levels = levels(data_rob$subdomain))) %>%
    dplyr::select(-starts_with("n_"))


  out <- dplyr::bind_rows(data_rob, data_rob_overall, data_app, data_app_overall) %>%
    dplyr::select(id:subdomain, assess, item, value) %>%
    dplyr::mutate(assess = factor(assess, levels = c("Low", "Unclear", "High")))

  return(out)}
