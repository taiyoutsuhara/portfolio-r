## Shiny Dashboardの描画 ##

color_list_at_skin = c("blue", "black", "purple", "green", "red", "yellow")
ui =
  dashboardPage(
    dashboardHeader(title = "Service Comparison Dashboard"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Information", icon = icon("info"), tabName = 'tab_Info'),
        menuItem("Ranking", icon = icon("line-chart"),
                 menuSubItem("Comparison", tabName = 'tab_Comparison'),
                 menuSubItem("Ranking", tabName = 'tab_Ranking'))
      )
    ),
    dashboardBody(
      tabItems(
        tabItem_Info,
        tabItem_Comparison,
        tabItem_Ranking
      )
      
    ),
    skin = color_list_at_skin[1]
  )