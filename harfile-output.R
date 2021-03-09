if (!require(tidyverse)) install.packages("tidyverse")
if (!require(HARtools)) install.packages("HARtools")
if (!require(splashr)) install.packages("splashr")
if (!require(ggrepel)) install.packages("ggrepel")
if (!require(scales)) install.packages("scales")

# Function: Read in har file,  return data frame --------------------------
get_harspeed <- function(file) {
  harfile <- readHAR(file)
  
  get_speeds <- function(li) {
    url <- li$request$url
    time <- li$time
    request_method <- li$request$method
    response_size <- li$response$content$size
    data.frame(url = url,
               time = time,
               request_method = request_method,
               response_size = response_size)
  }
  
  # Convert nested/repeated harfile structure to data frame
  res <- map_df(harfile$log$entries, get_speeds) %>% 
    mutate(page = str_replace_all(.$url[1], ".*\\.com", ""))
  
  tidy <- res %>% 
    mutate(domain = str_replace_all(url, ".*\\/\\/", "")) %>% 
    mutate(domain = str_replace_all(domain, "\\/.*", ""),
           mf_int = case_when(
             str_detect(url, "mouseflow\\.com/(dom|events)") ~ "Mouseflow Interactive event",
             # Assumption: requests to mouseflow.com with 
             # dom/events query string are in response to user interaction, not part of page load
             TRUE ~ "Non-interactive event"
           ))
  tidy
}

args_in <- commandArgs(trailingOnly = TRUE)
file_safe <- stringr::str_replace_all(args_in, "^a-zA-Z0-9", "_")
stopifnot("You must only supply one argument to this script" = length(args_in) == 1)

har_df <- get_harspeed(args_in)
page_safe <- str_replace_all(har_df$page[1], "[^a-zA-Z0-9]", "_")

reqs <- har_df %>% 
    group_by(domain, mf_int) %>% 
    summarise(time = sum(time)) %>% 
    ungroup() %>% 
    mutate(domain = fct_reorder(domain, time)) %>% 
    ggplot(aes(domain, time, fill = mf_int)) + 
    geom_col() + 
    theme_bw() +
    coord_flip() +
    scale_y_continuous(labels = scales::comma) +
    labs(y = "Time (ms)", x = "Request domain", title = paste0("Requests summary by domain"),
         subtitle = paste0("Page: ", har_df$page[1]),
         fill = "Script type (estimated)") +
    theme(plot.title.position = "plot",
          legend.position = "bottom",
          legend.text = element_text(size = 5), legend.title = element_text(size = 6)) +
  scale_fill_brewer()

ggsave(reqs, filename = paste0("requests_", page_safe, ".png"), width = 150, height = 180, units = "mm")

top_df <- har_df %>% 
  filter(!str_detect(mf_int, "Mouse")) %>% 
  top_n(20, time) %>% 
  mutate(item = case_when(
    str_detect(url, "dtm") ~ "DTM",
    str_detect(url, "/bundles") ~ str_replace_all(url, ".*bundles/|\\?.*", ""),
    str_detect(url, "cdn\\.") ~ paste0("Asset ID: ", str_replace_all(url, ".*assetid=", "")),
    str_detect(url, "oveo") ~ "CoveoHive",
    TRUE ~ domain
  ))

scatter <- har_df %>% 
  ggplot(aes(response_size, time)) +
  geom_point() +
  theme_bw() + 
  geom_label_repel(data = top_df, aes(label = item)) +
  labs(title = "Scatter of response size (x-axis) vs download time (y-axis), cytiva homepage",
       x = "Response size (B)", y = "Time (ms)") +
  theme_bw() + 
  scale_x_continuous(labels = comma)

ggsave(scatter, filename = paste0("scatter_", page_safe, ".png"), width = 450, height = 450, units = "mm")

top_scatter <- top_df %>% 
  ggplot(aes(response_size, time)) +
  geom_point() +
  theme_bw() +
  geom_label_repel(data = top_df, aes(label = item)) +
  labs(title = "Scatter of response size (x-axis) vs download time (y-axis)\ntop 20 requests by response time",
       subtitle = paste0("Page: ", har_df$page[1]),
       x = "Response size (B)", y = "Time (ms)") +
  theme_bw() + 
  scale_x_continuous(labels = comma)

ggsave(top_scatter, filename = paste0("scatter_", page_safe, "_top20.png"), width = 350, height = 350, units = "mm")

write_excel_csv(har_df, paste0("tabular_har_", page_safe, ".csv"))
 