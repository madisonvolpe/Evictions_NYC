## NYC_HVS replicate weights function 

# Old what I based function on 
# # Convert factors to numeric
# x <- hvs %>% 
#   mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
#   mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x)))
# 
# # Calculate the full sample weighted survey estimate
# N0 <- sum(x[,'hhweight'])/100000
# 
# # Calculate the weighted survey estimate for each of the replicate samples.
# Nr <- x %>%
#       summarise_at(vars(matches("^FW")), function(x) sum(x)/100000)
# 
# # calculate variance 
# sq <- (Nr-N0)^2    
# 
# var <- .05*rowSums(sq)
# 
# # calculate SE, which is sqrt of variance 
# SE <- sqrt(var)

rep.wts.SE<-function(df){
  
  # Convert factors to numeric
  df <- df %>%
        mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
        mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x)))
  
  # Calculate the full sample weighted survey estimate
  N0 <- sum(df[,'hhweight'])/100000
  
  # Calculate the weighted survey estimate for each of the replicate samples.
  Nr <- df %>%
    summarise_at(vars(matches("^FW")), function(x) sum(x)/100000)
  
  # calculate variance 
  sq <- (Nr-N0)^2    
  
  var <- .05*rowSums(sq)
  
  # calculate SE, which is sqrt of variance 
  SE <- sqrt(var)
  
  return(SE)
  
}

divide.by.5 <- function(x){
  x <- x/100000
  return(x)
}

#Old what I based function on 

  # x <- moved %>%
  #   select(sba.name, X_6, hhweight, starts_with("FW"))%>%
  #   mutate(sba.name = as.character(sba.name)) %>%
  #   mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
  #   mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x))) %>%
  #   filter(X_6 == 'Evicted, displaced, landlord harassment') %>%
  #   group_by(sba.name) %>%
  #   mutate(N0=sum(hhweight)/100000)%>%
  #   arrange(desc(N0)) %>%
  #   mutate_at(.vars = vars(starts_with("FW")),
  #             .funs = funs(Nr= sum)) %>%
  #   mutate_at(.vars = vars(ends_with("Nr")),
  #             .funs = funs(divide.by.5)) %>%
  #   select(sba.name, N0, ends_with("Nr")) %>%
  #   distinct() %>%
  #   mutate_at(.vars = vars(starts_with("FW")),
  #             .funs = funs(((.-N0)^2))) %>%
  #  ungroup() %>%
  #  mutate(NrFinal = rowSums(select(., starts_with("FW")))) %>%
  #  mutate(Var = NrFinal * .05) %>%
  #  mutate(SE = sqrt(Var))%>%
  #  select(sba.name, N0, Var, SE)

rep.wts.grp.SE <- function(df, grpvar){
    
    #so function works
    grpvar <- enquo(grpvar)
    
    df <- df %>%
    
    #selects group variable, the weight, and replicate weights
    select(!! grpvar, hhweight, starts_with("FW"))%>% 
    
    #puts factors into numeric form to allow for addition, subtraction, etc. 
    mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
    mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x))) %>%
    
    #group by the group variable
    group_by(!! grpvar) %>%
    
    #calculate full sample estimate (N0)
    mutate(N0=sum(hhweight)/100000)%>%
    arrange(desc(N0)) %>%
    
    #calculate the sum of 80 replicate weights for each group
    mutate_at(.vars = vars(starts_with("FW")),
              .funs = funs(Nr= sum)) %>%
    mutate_at(.vars = vars(ends_with("Nr")),
              .funs = funs(divide.by.5)) %>%
    
    # select the grp var, full estimate, and the sum of each replicate weight
    select(!! grpvar, N0, ends_with("Nr")) %>%
    distinct() %>%
    
    # from the sum of each replicate weight subtract N0 (full sample estimate) + sq 
    mutate_at(.vars = vars(starts_with("FW")),
              .funs = funs(((.-N0)^2))) %>%
    
    # for each group variable get the sum of all 80 replicate weights (NrFinal)!
    ungroup() %>%
    mutate(NrFinal = rowSums(select(., starts_with("FW")))) %>%
    
    # multiply NrFinal by .05 this creates the variance estimate 
    mutate(Var = NrFinal * .05) %>%
    
    # Take sqrt of variance to get the SE
    mutate(SE = sqrt(Var)) %>%
    
    #select the grp variable, the N0 (full sample estimate), var, and SE estimates
    select(!! grpvar, N0, Var, SE)

  return(df)
  
}
  

rep.wts.2grps.SE <- function(df, grpvar1, grpvar2){
  
  #so function works
  grpvar1 <- enquo(grpvar1)
  grpvar2 <- enquo(grpvar2)
  
  df <- df %>%
    
    #selects group variable, the weight, and replicate weights
    select(!! grpvar1, !!grpvar2, hhweight, starts_with("FW"))%>% 
    
    #puts factors into numeric form to allow for addition, subtraction, etc. 
    mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
    mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x))) %>%
    
    #group by the group variable
    group_by(!! grpvar1, !! grpvar2) %>%
    
    #calculate full sample estimate (N0)
    mutate(N0=sum(hhweight)/100000)%>%
    arrange(desc(N0)) %>%     
    
    #calculate the sum of 80 replicate weights for each group
    mutate_at(.vars = vars(starts_with("FW")),
              .funs = funs(Nr= sum)) %>%
    mutate_at(.vars = vars(ends_with("Nr")),
              .funs = funs(divide.by.5)) %>%
    
    # select the grp var, full estimate, and the sum of each replicate weight
    select(!! grpvar1,!! grpvar2, N0, ends_with("Nr")) %>%
    distinct() %>%
    
    # from the sum of each replicate weight subtract N0 (full sample estimate) + sq 
    mutate_at(.vars = vars(starts_with("FW")),
              .funs = funs(((.-N0)^2))) %>% 
    
    # for each group variable get the sum of all 80 replicate weights (NrFinal)!
    ungroup() %>%
    mutate(NrFinal = rowSums(select(., starts_with("FW")))) %>%
    
    # multiply NrFinal by .05 this creates the variance estimate 
    mutate(Var = NrFinal * .05) %>%
    
    # Take sqrt of variance to get the SE
    mutate(SE = sqrt(Var)) %>%
    
    #select the grp variable, the N0 (full sample estimate), var, and SE estimates
    select(!! grpvar1 ,!! grpvar2, N0, Var, SE) %>%
    
    #arrange by neighborhood name
    arrange(sba.name)
  
    return(df)  
}

 # TEST
 # ex <- evicted.displaced %>%
 #  
 #  #selects group variable, the weight, and replicate weights
 #  select(sba.name, RaceSimplified, hhweight, starts_with("FW"))%>% 
 #  
 #  #puts factors into numeric form to allow for addition, subtraction, etc. 
 #  mutate(hhweight = as.numeric(as.character(hhweight))) %>% 
 #  mutate_at(vars(matches("^FW")), function (x) as.numeric(as.character(x))) %>%
 #  
 #  #group by the group variable
 #  group_by(sba.name, RaceSimplified) %>%
 #    
 #  #calculate full sample estimate (N0)
 #  mutate(N0=sum(hhweight)/100000)%>%
 #  arrange(desc(N0)) %>%     
 # 
 #  #calculate the sum of 80 replicate weights for each group
 #  mutate_at(.vars = vars(starts_with("FW")),
 #            .funs = funs(Nr= sum)) %>%
 #  mutate_at(.vars = vars(ends_with("Nr")),
 #            .funs = funs(divide.by.5)) %>%
 # 
 #  # select the grp var, full estimate, and the sum of each replicate weight
 #  select(sba.name,RaceSimplified, N0, ends_with("Nr")) %>%
 #  distinct() %>%
 #   
 #  # from the sum of each replicate weight subtract N0 (full sample estimate) + sq 
 #  mutate_at(.vars = vars(starts_with("FW")),
 #            .funs = funs(((.-N0)^2))) %>% 
 #   
 #  # for each group variable get the sum of all 80 replicate weights (NrFinal)!
 #  ungroup() %>%
 #  mutate(NrFinal = rowSums(select(., starts_with("FW")))) %>%
 #   
 #  # multiply NrFinal by .05 this creates the variance estimate 
 #  mutate(Var = NrFinal * .05) %>%
 #   
 #  # Take sqrt of variance to get the SE
 #  mutate(SE = sqrt(Var)) %>%
 #   
 #  #select the grp variable, the N0 (full sample estimate), var, and SE estimates
 #  select(sba.name,RaceSimplified, N0, Var, SE) %>%
 #  
 #  #arrange by neighborhood name
 #  arrange(sba.name)
  
  
  