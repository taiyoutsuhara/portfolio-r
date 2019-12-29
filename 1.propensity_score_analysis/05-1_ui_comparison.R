## 比較したいサービスを選ぶ画面 ##

tabItem_Comparison = tabItem(
  "tab_Comparison",
  h2("Comparison"),
  tabPanel_of_Comparison,
  titlePanel("Available Combinations"),
  dataTableOutput("available_combiniations")
)