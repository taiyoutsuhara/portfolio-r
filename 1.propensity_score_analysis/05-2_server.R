## 前段で設計した各パーツを読み込み、アプリケーションを起動する。 ##

server = function(input, output){
  # サービスの概要@ Information
  output$service_description = renderDataTable(code_of_service,
                                               options = list(scrollY = "500px",
                                                              scrollCollapse = T)
  )
  
  # 選択可能パターン表@ Comparison
  output$available_combiniations = renderDataTable(dataframe_to_pick_comparison,
                                                   options = list(scrollY = "500px",
                                                                  scrollCollapse = T)
  )
  
  # 可視化@ Ranking
  output$plot <- renderPlot({
    # 可視化
    dataframe_for_ggplot2 =
      rbind(dataframe_for_ggplot2_at_1st_Comparison[[input$`1st_Comparison`]],
            dataframe_for_ggplot2_at_2nd_Comparison[[input$`2nd_Comparison`]],
            dataframe_for_ggplot2_at_3rd_Comparison[[input$`3rd_Comparison`]])
    ggplot(dataframe_for_ggplot2, aes(x = Service.Type, y = Outcome, fill = Comparison)) +
      geom_bar(position = "dodge", stat = "identity") + # グルーピング用パラメータ
      ylim(c(0, max(dataframe_for_ggplot2$Outcome))) +
      scale_y_continuous(name = "Outcome", labels = comma) # "1e+00"表記回避用パラメータ
  })
  
  output$plot_dbl_click_info <- renderPrint({
    cat("Double-clicked point:\n")
    str(input$plot_dbl_click)
  })  
}