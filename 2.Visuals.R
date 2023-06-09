##--libraries-------------------------------------------------------------------
library(plotly)
library(RColorBrewer)
library(leaflet)
library(sf)
library(waffle)
library(sfheaders)

##--sourcing R file-------------------------------------------------------------------
source("1.Data_Wrangle.R")

##--1. CES Data: Employment Trends in Construction---------------------------------------------
ces_data <- rbind(ces_employees, ces_pctchange)

# line graph of employment over time 
ces_fig <- ces_data %>% 
  plot_ly(
    type = "scatter", 
    mode = "lines", 
    x =~ date, 
    y =~ values,
    color =~ type,
    colors = c("#1097FF","#FF4900"),
    text =~ type,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y}")
  ) %>% 
  layout(
  title = list(text="<br>      Employment Trends in the Construction Industry<br>      in Greater Philadelphia",
               x=0,y=1),
  font = list(family = "Georgia", color = "darkslategrey"),
  hoverlabel = list(font = list(family = "Georgia")),
  yaxis = list(title = "Employment Trends"),
  xaxis = list(title = "",
               rangeslider = list(type = "date")),
  legend = list(
    orientation = "h",
    xanchor = "center",
    x = 0.5,
    yanchor = "top",
    y = -0.3
  ),
  annotations = list(
    x = 1.05, # X position of the caption (right side of the plot)
    y = 1.1, # Y position of the caption (top of the plot)
    text = "Source: CES Data Estimates", # The text of the caption
    showarrow = FALSE, # Don't show an arrow pointing to the caption
    xref = "paper", # Set the X position reference to the plot area
    yref = "paper", # Set the Y position reference to the plot area
    font = list(size = 9, color = "grey80"), # Set the font size of the caption
    align = "right", # Align the caption to the right
    xanchor = "right", # Anchor the caption to the right side of the plot
    yanchor = "top" # Anchor the caption to the top of the plot
  ),
  margin = list(l = 70, r = 70, b = 50, t = 80)
  )

ces_fig


##--2a. ACS Data: Filters for Construction Ethnic Proportions----------------------------------------------

# filtering for just race variables 
acs_race <- acs_dta %>% 
  filter(variable != "total_employees" & 
      variable != "total_female" & 
      variable != "total_male" & 
      variable != "fulltime_female" & 
      variable != "fulltime_male" & 
      variable != "total_white" &
      variable != "total_black" &
      variable != "total_native" &
      variable != "total_asian" &
      variable != "total_hawaii" &
      variable != "total_otherrace" &
      variable != "total_multirace" &
      variable != "total_hispanic"
      )

# Separate ethnicity column into race and gender columns
acs_race <- separate(acs_race, variable, into = c("race", "gender"), sep = "_")

# Summing by ethnicity 
acs_race <- acs_race %>% 
  group_by(Year, NAME, race) %>% 
  mutate(total_estimate = sum(estimate, na.rm = TRUE)) %>% 
  distinct(total_estimate, .keep_all = TRUE)

# Removing "white" race category since it double counts as hispanic AND white
acs_race <- acs_race %>% 
  filter(race != "whiteNONHISPANIC") %>% 
  mutate(Year = as.factor(Year),
         race = as.factor(race)) 

# Generating proportional employment by race excluding hispanics
acs_race_nothispanic <- acs_race %>% 
  filter(race != "hispanic") %>% 
  group_by(Year, NAME) %>% 
  mutate(emp_prop = (total_estimate/sum(total_estimate, na.rm = TRUE)) * 100) %>% 
  distinct(emp_prop, .keep_all = TRUE) %>% 
  filter(emp_prop != 0)
  
# Generating proportional employment by race including hispanics
acs_race_hispanic <- acs_race %>% 
  group_by(Year, NAME) %>% 
  mutate(emp_prop = (total_estimate/sum(total_estimate, na.rm = TRUE)) * 100) %>% 
  distinct(emp_prop, .keep_all = TRUE) %>% 
  filter(race == "hispanic")
  

##--2b.1 ACS Data: Graph Ethnic Proportions Over Time (EXLUDING HISPANICS)-----------

# Generate color palette
my_colors <- c("#FFBF00", "#7915FF",  
               "#FF4900", "grey20", "#1097FF")  

# bar graph of ethnic proportions of employment over time 
acs_race_fig <- acs_race_nothispanic %>% 
  filter(NAME == "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD Metro Area") %>% 
  plot_ly(
    type = 'bar',
    x =~ as.factor(Year), 
    y =~ emp_prop,
    color =~ race,
    colors = my_colors,
    text =~ race,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y:.1f}%")
  ) %>% 
  layout(barmode = 'stack',
         title = list(text="<br>      Employment Trends in the Construction Industry<br>      in Greater Philadelphia by Ethnicity",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Proportion of Employees (%)"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: ACS Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         margin = list(l = 70, r = 70, b = 50, t = 80)
         )

acs_race_fig



##--2b.2 ACS Data: Graph Ethnic Proportions Over Time (INCLUDING HISPANICS)-----------

# bar graph of ethnic proportions of employment over time 
acs_hispanic_fig <- acs_race_hispanic %>% 
  filter(NAME == "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD Metro Area") %>% 
  plot_ly(
    type = 'bar',
    x =~ as.factor(Year), 
    y =~ emp_prop,
    color =~ race,
    colors = "#FF4900",
    text =~ race,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y:.1f}%")
  ) %>% 
  layout(title = list(text="<br>      Employment Trends in the Construction Industry<br>      in Greater Philadelphia Among Hispanics",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Proportion of Employees (%)"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: ACS Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         margin = list(l = 70, r = 70, b = 50, t = 80)
  )

acs_hispanic_fig


##--2c. ACS Data: Filter AND Graph for Gender Proportions----------------------------------------------

# filtering for gender variables 
acs_gender <- acs_dta %>% 
  filter(variable == "total_employees" |
           variable == "total_female" | 
           variable == "total_male" | 
           variable == "fulltime_female" | 
           variable == "fulltime_male"
  ) 

# Generate color palette
my_colors <- c("#FF9200", "darkslategrey", "#FF4900", 
               "#7915FF", "#FFBF00", "#1097FF")  

# line graph of employment trends by gender
acs_gender_fig <- acs_gender %>%
  filter(NAME == "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD Metro Area") %>% 
  filter(variable != "total_employees") %>% 
  plot_ly(
    type = "scatter", 
    mode = "lines+markers", 
    x =~ as.factor(Year), 
    y =~ estimate,
    color =~ variable,
    colors = my_colors,
    text =~ variable,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y}")
  ) %>% 
  layout(
         title = list(text="<br>      Employment Trends in the Construction Industry<br>      in Greater Philadelphia by Gender",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Number of employees"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: ACS Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         
         margin = list(l = 70, r = 70, b = 50, t = 80)
  )
  

acs_gender_fig



##--2d. ACS Data: Filters for Ethnic Makeup of GRPHL--------------------------------

acs_pop <- acs_dta %>% 
  filter(variable == "total_white" |
         variable == "total_black" |
         variable == "total_native" |
         variable == "total_asian" |
         variable == "total_hawaii" |
         variable == "total_otherrace" |
         variable == "total_multirace" |
         variable == "total_hispanic")

# creating race variable for merging
acs_pop$variable <- sub("total_", "", acs_pop$variable)

# renaming race variable 
acs_pop <- acs_pop %>% 
  rename(race = variable)
  
# calculating proportions for each race 
acs_pop <- acs_pop %>% 
  group_by(Year, NAME) %>% 
  mutate(total_pop = sum(estimate),
         ethnic_prop = (estimate/sum(estimate, na.rm = TRUE)) * 100)



##--2e. ACS Data: Combining Construction Ethnic Data and Overall Ethnic Data----

# calculating proportions of employees by race in the employee data

temp_dta1 <- acs_race %>% 
  group_by(Year, NAME) %>% 
  mutate(emp_prop = (total_estimate/sum(total_estimate, na.rm = TRUE)) * 100) %>% 
  distinct(emp_prop, .keep_all = TRUE) %>% 
  select(-c(gender, estimate, total_estimate))

temp_dta2 <- acs_pop %>% 
  select(-c(estimate, total_pop))

ethnic_merge <- temp_dta1 %>% 
  inner_join(temp_dta2, by = c("Year", "GEOID", "NAME", "race"))

# calculating over/under representation in construction industry by ethnicity 
ethnic_merge <- ethnic_merge %>% 
  group_by(NAME, race) %>% 
  mutate(avg_employment = mean(emp_prop, na.rm = TRUE),
         avg_ethnicity = mean(ethnic_prop, na.rm = TRUE)
         ) %>% 
  distinct(avg_employment, .keep_all = TRUE) %>% 
  select(-c(emp_prop, ethnic_prop)) %>% 
  gather(variable, proportion, avg_employment:avg_ethnicity)



##--2f. ACS Data: Graph of Under representation in Construction Industry--------

acs_map <- ethnic_merge %>% 
  filter(NAME == "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD Metro Area" & 
           race != "hawaii") %>% 
  arrange(proportion) %>% 
  plot_ly(
    type = 'bar',
    x =~ reorder(race, proportion), 
    y =~ proportion,
    color =~ variable,
    colors = c("#1097FF","#FF4900"),
    text =~ race,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y:.1f}%")
  ) %>%
  layout(title = list(text="<br>      10-year Average Employment Distribution and Ethnic Makeup of Residents<br>      in the Construction Industry in Greater Philadelphia",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Proportion (%)", tickformat = "%d%%"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: ACS Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         margin = list(l = 70, r = 70, b = 50, t = 70)
  )
acs_map



##--2g.1. ACS Data: Ethnic Proportions at County level----------------------------------------------

# filtering for just race variables 
acs_race_county <- acs_county_dta %>% 
  filter(variable != "total_employees" & 
           variable != "total_female" & 
           variable != "total_male" & 
           variable != "fulltime_female" & 
           variable != "fulltime_male" & 
           variable != "total_white" &
           variable != "total_black" &
           variable != "total_native" &
           variable != "total_asian" &
           variable != "total_hawaii" &
           variable != "total_otherrace" &
           variable != "total_multirace" &
           variable != "total_hispanic"
  )

# Separate ethnicity column into race and gender columns
acs_race_county <- separate(acs_race_county, variable, into = c("race", "gender"), sep = "_")

# Summing by ethnicity 
acs_race_county <- acs_race_county %>% 
  group_by(Year, NAME, race) %>% 
  mutate(total_estimate = sum(estimate, na.rm = TRUE)) %>% 
  distinct(total_estimate, .keep_all = TRUE)

# Removing whiteNONHISPANICS 
acs_race_county <- acs_race_county %>% 
  filter(race != "whiteNONHISPANIC") %>% 
  mutate(Year = as.factor(Year),
         race = as.factor(race)) 

# Generating proportional employment by race
acs_race_county <- acs_race_county %>% 
  group_by(Year, NAME) %>% 
  mutate(emp_prop = (total_estimate/sum(total_estimate, na.rm = TRUE)) * 100) %>% 
  distinct(emp_prop, .keep_all = TRUE) %>% 
  filter(emp_prop != 0)

##--2g.2. ACS Data: Ethnic Proportions AND Population at County level------------

acs_pop <- acs_county_dta %>% 
  filter(variable == "total_white" |
           variable == "total_black" |
           variable == "total_native" |
           variable == "total_asian" |
           variable == "total_hawaii" |
           variable == "total_otherrace" |
           variable == "total_multirace" |
           variable == "total_hispanic")

# creating race variable for merging
acs_pop$variable <- sub("total_", "", acs_pop$variable)

# renaming race variable 
acs_pop <- acs_pop %>% 
  rename(race = variable)

# calculating proportions for each race 
acs_pop <- acs_pop %>% 
  group_by(Year, NAME) %>% 
  mutate(total_pop = sum(estimate),
         ethnic_prop = (estimate/sum(estimate, na.rm = TRUE)) * 100)



##--2g.3. ACS Data: Combining County Ethnic Data and Overall Ethnic Data----

# calculating proportions of employees by race in the employee data

temp_dta1 <- acs_race_county %>% 
  select(-c(gender, estimate, total_estimate))

temp_dta2 <- acs_pop %>% 
  select(-c(estimate, total_pop))

ethnic_merge <- temp_dta1 %>% 
  inner_join(temp_dta2, by = c("Year", "GEOID", "NAME", "race"))

# calculating over/under representation in construction industry by ethnicity 
ethnic_merge <- ethnic_merge %>%
  group_by(Year, NAME) %>% 
  mutate(diff_prop = emp_prop - ethnic_prop) 

# calculating average difference in representation by county
ethnic_merge <- ethnic_merge %>% 
  group_by(GEOID, race) %>% 
  mutate(avg_diff_prop = mean(diff_prop, na.rm = TRUE)) %>% 
  distinct(avg_diff_prop, .keep_all = TRUE)

##--2g.4. ACS Data: Lollipop Plot of Representation in Construction Industry----

ethnic_merge %>%
  filter(NAME == "Philadelphia County, Pennsylvania") %>% 
  ggplot(aes(x=reorder(race, avg_diff_prop),  y=avg_diff_prop)) +
  geom_segment(aes(x=reorder(race, avg_diff_prop), xend=reorder(race, avg_diff_prop), 
                    y=0, yend=avg_diff_prop), color="#1097FF") +
  geom_point( color="#FF4900", size=4) +
  geom_hline(yintercept = 0, color = "grey") +
  theme_light() +
  theme(
    panel.grid.major.x = element_blank(),
    panel.border = element_blank(),
    axis.ticks.x = element_blank()
  ) +
  xlab("") +
  ylab("Value of Y")
  

##--2g.4. ACS Data: MAP of Counties whose construction sector looks the least like their ethnic proportion----

ethnic_map <- ethnic_merge %>% 
  group_by(NAME) %>% 
  mutate(map_diff = sum(avg_diff_prop))

ethnic_map <- ethnic_map %>% 
  group_by(NAME) %>% 
  distinct(map_diff, .keep_all = TRUE) %>% 
  mutate(GEOID = as.integer(GEOID))

# merge with shape files of counties
ethnic_map <- ethnic_map %>% 
  inner_join(acs_map_dta, by = c("GEOID", "NAME")) %>% 
  filter(!is.na(map_diff))

# turning data frame into an 'sf' object for the leaflet package
ethnic_map$geometry <- st_as_text(ethnic_map$geometry)
GIS_data_sf <- st_as_sf(ethnic_map, wkt = "geometry")

# Create color palettes for each variable
pal2 <- colorNumeric(palette = "Spectral", domain = ethnic_map$map_diff)

map <- leaflet(GIS_data_sf) %>%
  addTiles() %>%
  addPolygons(
    group = "map_diff",
    fillColor = ~pal2(map_diff),
    fillOpacity = 0.7,
    color = "#444444",
    weight = 1,
    popup = ~paste("County: ", NAME, "<br>",
                   "Difference", round(map_diff,2))
  )
# Set the initial view of the map to the center of the United States
map <- map %>% setView(
  lng = -98.583333,
  lat = 39.833333,
  zoom = 4
) %>% addLegend(
  pal = pal2,
  values = ~map_diff,
  position = "bottomright",
  title = "Representation (%)"
)
# Print map
map


##--3a. IPUMS Data: filtering for Self-Employed Respondents-----------------------

ipums_construction <- ipums_construction %>% 
  filter(CLASSWKR == "Self-employed" & 
           IND != 3080) # removing this industry code because of almost all 0 values across years

# combining asian race classification
ipums_construction <- ipums_construction %>% 
  mutate(RACE_adj = as.factor(as.character(RACE_adj)),
    RACE_adj = ifelse(RACE_adj == "Chinese", "Asian", 
                       ifelse(RACE_adj == "Japanese", "Asian",
                              ifelse(RACE_adj == "Other Asian or Pacific Islander", "Asian",
                                     ifelse(RACE_adj == "Other race, nec", "Other",
                                            ifelse(RACE_adj == "Two major races", "Multi-Ethnic",
                                                   ifelse(RACE_adj == "Three or more major races", "Multi-Ethnic",
                                                          ifelse(RACE_adj == "White", "White",
                                                                 ifelse(RACE_adj == "Black/African American", "Black/African American",
                                                                        ifelse(RACE_adj == "American Indian or Alaska Native", "American Indian or Alaska Native",
                                                                               ifelse(RACE_adj == "Hispanic", "Hispanic", RACE_adj)))))))))))
# summing employers by race 
ipums_construction <- ipums_construction %>% 
  group_by(YEAR, RACE_adj) %>% 
  mutate(Freq_adj = sum(Freq)) %>% 
  distinct(Freq_adj, .keep_all = TRUE) %>% 
  group_by(YEAR) %>% 
  mutate(prop_employers = (Freq_adj/sum(Freq_adj, na.rm = TRUE)) *100)

##--3b. IPUMS Data: Employer Mapping by Ethnicity-----------------------

# Generate color palette
my_colors <- c("grey", "#FF9200", "darkslategrey", "#FF4900", 
               "#7915FF", "#FFBF00", "#1097FF")  

# bar graph of ethnic proportions of employers over time 
ipums_race_fig <- ipums_construction %>% 
  plot_ly(
    type = 'bar',
    x =~ YEAR, 
    y =~ prop_employers,
    color =~ RACE_adj,
    colors = my_colors,
    text =~ RACE_adj,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y:.1f}%")
  ) %>% 
  layout(barmode = 'stack',
         title = list(text="<br>      Employer Trends in the Construction Industry<br>      in Greater Philadelphia by Ethnicity",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Proportion of Employers (%)"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: IPUMS USA Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         margin = list(l = 70, r = 70, b = 50, t = 70)
  )

ipums_race_fig




##--3c. IPUMS Data + ACS Data: Mapping Employer and Ethnic Distributions------------------------

# creating temporary data to match with ACS data 
temp_dta3 <- ipums_construction %>% 
  mutate(RACE_adj = tolower(RACE_adj),
         RACE_adj =ifelse(RACE_adj == "black/african american", "black",
                          ifelse(RACE_adj == "multi-ethnic", "multirace",
                                 ifelse(RACE_adj == "american indian or alaska native", "native",
                                        ifelse(RACE_adj == "other", "otherrace", RACE_adj))))
         ) %>% 
  rename(race = RACE_adj, 
         Year = YEAR) %>% 
  select(Year, race, prop_employers)

# merging datasets
temp_dta4 <- temp_dta2 %>% 
  filter(NAME == "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD Metro Area")

employer_map <- temp_dta4 %>% 
  left_join(temp_dta3, by = c("Year", "race")) %>% 
  filter(!is.na(prop_employers) | prop_employers == 0)

# generating average employer and ethnic distributions
employer_map <- employer_map %>% 
  group_by(race) %>% 
  mutate(avg_ethnicity = mean(ethnic_prop, na.rm = TRUE),
         avg_employer = mean(prop_employers, na.rm = TRUE)
         ) %>% 
  distinct(avg_ethnicity, .keep_all = TRUE) %>% 
  select(-c(ethnic_prop, prop_employers)) %>% 
  arrange(avg_employer)

##--3d. IPUMS Data + ACS Data: Graph Employer and Ethnic Distributions------------------------
emp_map_figure <-   plot_ly(data = employer_map, 
                    x = ~reorder(race, avg_employer),
                    y = ~avg_employer, 
                    name = "Average Employer Proportion", 
                    type = 'bar',
                    marker = list(color = '#FF4900')) %>%
  
  add_trace(y = ~avg_ethnicity, 
            name = "Average Ethnic Proportion", 
            type = 'bar',
            marker = list(color = '#1097FF')) %>% 
  
  layout(
    title = list(text="<br>      10-year Average Employer Distribution and Ethnic Makeup of Residents",
                 x=0,y=1),
    font = list(family = "Georgia", color = "darkslategrey"),
    hoverlabel = list(font = list(family = "Georgia")),
    yaxis = list(title = "Proportion (%)"),
    xaxis = list(title = ""),
    legend = list(
      orientation = "h",
      xanchor = "center",
      x = 0.5,
      yanchor = "top",
      y = -0.1
    ),
    annotations = list(
      x = 1.05, # X position of the caption (right side of the plot)
      y = 1.1, # Y position of the caption (top of the plot)
      text = "Source: IPUMS and ACS Data Estimates", # The text of the caption
      showarrow = FALSE, # Don't show an arrow pointing to the caption
      xref = "paper", # Set the X position reference to the plot area
      yref = "paper", # Set the Y position reference to the plot area
      font = list(size = 9, color = "grey80"), # Set the font size of the caption
      align = "right", # Align the caption to the right
      xanchor = "right", # Anchor the caption to the right side of the plot
      yanchor = "top" # Anchor the caption to the top of the plot
    ),
    margin = list(l = 70, r = 70, b = 50, t = 70)
  )
emp_map_figure



##--3e. IPUMS Data: Employer Distribution by Age--------------------------------

# Generate color palette
my_colors <- c("#FF9200", "#1097FF", "#FF4900", 
               "#7915FF", "#FFBF00")  

# bar graph of ethnic proportions of employers over time 
ipums_age_fig <- ipums_age %>% 
  plot_ly(
    type = 'bar',
    x =~ YEAR, 
    y =~ age_prop,
    color =~ age_bracket,
    colors = my_colors,
    text =~ age_bracket,
    hovertemplate=paste("<i>%{text} in %{x}:</i><br>%{y:.1f}%")
  ) %>% 
  layout(barmode = 'stack',
         title = list(text="<br>      Employer Trends in the Construction Industry<br>      in Greater Philadelphia by Age",
                      x=0,y=1),
         font = list(family = "Georgia", color = "darkslategrey"),
         hoverlabel = list(font = list(family = "Georgia")),
         yaxis = list(title = "Proportion of Employers (%)"),
         xaxis = list(title = ""),
         legend = list(
           orientation = "h",
           xanchor = "center",
           x = 0.5,
           yanchor = "top",
           y = -0.1
         ),
         annotations = list(
           x = 1.05, # X position of the caption (right side of the plot)
           y = 1.1, # Y position of the caption (top of the plot)
           text = "Source: IPUMS USA Data Estimates", # The text of the caption
           showarrow = FALSE, # Don't show an arrow pointing to the caption
           xref = "paper", # Set the X position reference to the plot area
           yref = "paper", # Set the Y position reference to the plot area
           font = list(size = 9, color = "grey80"), # Set the font size of the caption
           align = "right", # Align the caption to the right
           xanchor = "right", # Anchor the caption to the right side of the plot
           yanchor = "top" # Anchor the caption to the top of the plot
         ),
         margin = list(l = 70, r = 70, b = 50, t = 70)
  )

ipums_age_fig
##--3f. IPUMS Data: Employer Distribution by Gender--------------------------------

# Create a named vector of data
ipums_gender <- c(`Females`=5, `Males`= 95)

# Create a waffle plot
waffle(ipums_gender, rows=10,
       colors = c("#FF4900", "#1097FF"),
       legend_pos = "bottom") + 
  labs(title = "Proportion of Employers in the Construction Sector \nin Greater Philadelphia by Gender",
       caption = "Note: Each box represents one percentage of the entire construction industry \nin Greater Philadelphia. These estimates are 16-year average of employer \nproportion across gender.") + 
  theme(
    text = element_text(family = "Georgia", color = "darkslategrey"),
    plot.title = element_text(size = 14, hjust = 0),
    plot.caption = element_text(size = 8, hjust = 0, color = "grey50"))


##--4a. OES Data: Construction Wage Trends----------------------------------------

# filtering for "Manufacturing" and "All Occupations" 
oes_graph <- oes_philly %>% 
  filter(OCC_CODE == "47-0000" | OCC_CODE == "00-0000") %>% 
  select(PRIM_STATE, AREA, OCC_CODE, OCC_TITLE, year, H_MEAN_real, H_MEDIAN_real, A_MEAN_real, A_MEDIAN_real) %>% 
  gather(wage_type, amount, H_MEAN_real:A_MEDIAN_real) %>% 
  mutate(year_date = as.Date(paste0(year, "-01-01")),
         wage_type = ifelse(wage_type == "A_MEAN_real", "Mean Annual Wage",
                            ifelse(wage_type == "A_MEDIAN_real", "Median Annual Wage",
                                   ifelse(wage_type == "H_MEAN_real", "Mean Hourly Wage",
                                          ifelse(wage_type == "H_MEDIAN_real", "Median Hourly Wage", wage_type))))
         ) 

# ggplot of wages
oes_graph %>% 
  ggplot(aes(x=year_date, y = amount, color = OCC_TITLE)) + 
  geom_line(aes(linetype = OCC_TITLE, group = OCC_TITLE)) +  
  facet_wrap(~wage_type, scale = "free_y") + 
  scale_linetype_manual(values = c("dashed", "solid")) + 
  scale_color_manual(values = c("#1097FF", "#FF4900")) +
  scale_y_continuous(labels = function(x) paste0("$", x)) + 
  labs(y = "Wages", x = "", 
       title = "Wages in Greater Philadelphia for the Construction Sector",
       caption = "Note: All wages are inflation-adjusted to 2022 dollars. \nSource: OES Data") +
  theme_light() + 
  theme(axis.title = element_blank(),
        #panel.grid.major.x = element_blank(),
        #panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        legend.title = element_blank(),
        legend.justification = c(0, 1),
        legend.background = element_blank(),
        legend.position = "bottom",
        legend.direction="horizontal",
        legend.text = element_text(),
        text = element_text(family = "Georgia"),
        strip.text = element_text(color = "black"),
        plot.title = element_text(size = 15, margin = margin(b = 10, t = 5), color = "darkslategrey", hjust = 0.5),
        plot.subtitle = element_text(size = 10, color = "grey40", margin = margin(b = 10)),
        plot.caption = element_text(size = 8, margin = margin(t = 10), color = "grey50", hjust = 0),
        axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 10), color = "darkslategrey", ),
        axis.title.x = element_text(margin = margin(t = 10, r = 10, b = 0, l = 10), color = "darkslategrey", ),
        axis.ticks.x = element_blank(),
        plot.margin = margin(0.2,0.2,0.2,0.2, "cm"))




##--5a. GIS Data: Map of Wages by Metropolitan Regions in the U.S.--------------

# turning data frame into an 'sf' object for the leaflet package
GIS_data_sf <- st_as_sf(GIS_data, wkt = "geometry")

# Transform the data to the WGS84 SRS to remove the warning message from R
GIS_data_sf_transformed <- st_transform(GIS_data_sf, "+proj=longlat +datum=WGS84")

# Create color palettes for each variable
pal2 <- colorNumeric(palette = "YlOrRd", domain = GIS_data$H_MEDIAN)
pal4 <- colorNumeric(palette = "RdPu", domain = GIS_data$A_MEDIAN)

##--5c. GIS Data: Median Hourly Wage------------------------------------------------------
map <- leaflet(GIS_data_sf_transformed) %>%
  addTiles() %>%
  addPolygons(
    group = "H_MEDIAN",
    fillColor = ~pal2(H_MEDIAN),
    fillOpacity = 0.7,
    color = "#444444",
    weight = 1,
    popup = ~paste("Region: ", NAME, "<br>",
                   "Median Hourly Wage: $", round(H_MEDIAN,2))
  )
# Set the initial view of the map to the center of the United States
map <- map %>% setView(
  lng = -98.583333,
  lat = 39.833333,
  zoom = 4
) %>% addLegend(
  pal = pal2,
  values = ~H_MEDIAN,
  position = "bottomright",
  title = "Median Hourly Wage"
)
# Print map
map

##--5e. GIS Data: Median Annual Wage------------------------------------------------------
map <- leaflet(GIS_data_sf_transformed) %>%
  addTiles() %>%
  addPolygons(
    group = "A_MEDIAN",
    fillColor = ~pal4(A_MEDIAN),
    fillOpacity = 0.7,
    color = "#444444",
    weight = 1,
    popup = ~paste("Region: ", NAME, "<br>",
                   "Annual Median Wage: $", round(A_MEDIAN,2))
  )
# Set the initial view of the map to the center of the United States
map <- map %>% setView(
  lng = -98.583333,
  lat = 39.833333,
  zoom = 4
) %>% addLegend(
  pal = pal4,
  values = ~A_MEDIAN,
  position = "bottomright",
  title = "Median Annual Wage"
)
# Print map
map


