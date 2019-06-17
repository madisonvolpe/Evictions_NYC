build_df<- function(urls){
            buildings_dfs <- vector("list", length = nrow(ll_df))
            names(buildings_dfs) <- ll_df$landlord
            for(i in 1:length(urls)){
              
              buildings <- urls[i] %>%
                read_html()%>%
                html_nodes(xpath="//div[@style='padding-top:5px;']/div[@class='col-lg-12']/h2") %>%
                html_text()%>%
                trimws()
              
              headers <- urls[i] %>%
                read_html()%>%
                html_nodes(xpath = "//div[@style='padding-top:5px;']/div[@class='row']/div[@class='col-md-12']/h4/text()")%>%
                html_text() %>%
                str_remove_all(":")%>%
                trimws()%>%
                unique()
              
              rows <- urls[i] %>%
                read_html()%>%
                html_nodes(xpath = "//div[@style='padding-top:5px;']/div[@class='row']/div[@class='col-md-12']/h4/d")%>%
                html_text()
              
              rows <- matrix(rows, ncol = 6, byrow = T)
              rows <- data.frame(rows)
              names(rows) <- headers
              buildings_df <- rows
              buildings_df$building <-buildings
              
            buildings_dfs[[i]] <- buildings_df
            }
  buildings_dfs <- map_df(buildings_dfs, ~as.data.frame(.x), .id="Landlord")
  return(buildings_dfs)
}

try <- build_df(urls)

