# Documentation
#' Format TRIPOD data prior to plotting
#' @description  Format TRIPOD data prior to plotting
#' @param data TRIPOD data in format as specified in  "example_tripod.csv".
#' @param id  String specifying the column name containing the identifier for the specific paper/model.
#' @param type String specifying the column name containing the type of model ("d"=derivation, "dv" = "derivation and validation", "v" = validation)
#' @return Tibble of TRIPOD data formatted for a TRIPOD plot.
#' @import tibble
#' @import dplyr
#' @import tidyr
#' @export

tripod_format <- function(data, id = "id", type = "type"){

  # Clean-----------------
  var_item <- c("1", "2", "3a", "3b", "4a", "4b", "5a", "5b", "5c",
                "6a", "6b", "7a", "7b", "8", "9", "10a", "10b", "10c",
                "10d", "10e", "11", "12", "13a", "13b", "13c", "14a",
                "14b", "15a", "15b", "16", "17", "18", "19a", "19b", "20", "21", "22")

  columns <- c("id", "type", paste0("item_", var_item))

  data <- data %>%
    dplyr::mutate(id = pull(., id),
                  type = pull(., type)) %>%
    dplyr::select(id, type, starts_with("item_")) %>%
    dplyr::select(all_of(columns))

  # Check only 3 types
  check_type <- data %>% dplyr::filter(! type %in% c("d", "dvi", "dve", "dvie", "ve"))
  if(nrow(check_type)>0){stop(paste0("Please ensure all studies have one of 3 types assigned: d, dv, or v"))}

  out <- data %>%
    dplyr::mutate(across(everything(), function(x){as.character(x)})) %>%
    tidyr::pivot_longer(cols = starts_with("item_"), names_to = "item") %>%
    dplyr::mutate(item = stringr::str_remove_all(item, "item_")) %>%
    dplyr::mutate(value = tolower(value),
                  value = case_when(value %in% c("y", "yes", "yes (y)") ~ "Y",
                                    value %in% c("p", "partial", "partial (p)") ~ "P",
                                    value %in% c("n", "no", "no (n)") ~ "N",
                                    value %in% c("na", "not applicable", "not applicable (na)") ~ NA_character_)) %>%

    # Filter for items relevant for specific study design
    dplyr::filter(! (type=="ve"&item %in% c("10a", "10b", "14a", "14b", "15a", "15b"))) %>%
    dplyr::filter(! (type=="d"&item %in% c("10c", "10e", "12", "13c", "17", "19a"))) %>%
    dplyr::mutate(item = factor(item, levels = var_item),
                  value = factor(value, levels = c("N", "P", "Y"), labels = c("No", "Partial", "Yes")),
                  type = factor(type, levels = c("d", "dvi", "dve", "dvie", "ve"),
                                labels = c("Derivation",
                                           "Derivation +\nValidation (Internal)",
                                           "Derivation +\nValidation (External)",
                                           "Derivation +\nValidation (Both)",
                                           "Validation\n(External)")))

  # add check to make sure no remaining NA
  return(out)}
