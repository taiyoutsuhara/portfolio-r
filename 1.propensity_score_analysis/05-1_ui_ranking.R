## 推定結果の可視化 ##

# 可視化用データの用意 #
dataframe_for_ggplot2_at_1st_Comparison = dataframe_for_ggplot2_at_2nd_Comparison = dataframe_for_ggplot2_at_3rd_Comparison = list()
ranking_of_ipwe_including_all_zero = modifyList(list(rep(0, length_of_ServiceType - 1)), ranking_of_ipwe)
dataframe_for_ggplot2_at_1st_Comparison = lapply(ranking_of_ipwe_including_all_zero, function(x){make_dataframe_for_ggplot2(x, "1st")})
dataframe_for_ggplot2_at_2nd_Comparison = lapply(ranking_of_ipwe_including_all_zero, function(x){make_dataframe_for_ggplot2(x, "2nd")})
dataframe_for_ggplot2_at_3rd_Comparison = lapply(ranking_of_ipwe_including_all_zero, function(x){make_dataframe_for_ggplot2(x, "3rd")})

# 可視化画面 #
tabItem_Ranking = tabItem(
  "tab_Ranking",
  h2("Ranking"),
  # Layout for Ranking tab #
  plotOutput("plot",
             dblclick = dblclickOpts(id = "plot_dbl_click")
  ),
  verbatimTextOutput("plot_dbl_click_info")
)