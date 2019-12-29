## 比較したいサービスを選ぶ画面のパーツ ##

# 選択可能パターン表の読込み #
# 元データの読込み
coes_of_ipwe = ranking_of_ipwe = list()
ran.ranking_of_ipwe = c(1:length(batch4rank))
pattern_of_no_service = paste0("diff.data_", levels_of_ServiceType[length_of_ServiceType])
for(l in ran.ranking_of_ipwe){
  coes_of_ipwe[[l]] = fread(batch4rank[l],
                            data.table = F,
                            stringsAsFactors = F,
                            encoding = "UTF-8",
                            sep = ",")
  ranking_of_ipwe[[l]] = coes_of_ipwe[[l]][-length_of_ServiceType, grep(pattern_of_no_service, colnames(coes_of_ipwe[[l]]))]
  names(ranking_of_ipwe)[l] = gsub("./ipw-glm/|coes_|.csv", "", batch4rank[l])
}
detect_colname_of_Fi = strsplit(names(ranking_of_ipwe), "_")
range_of_Fi = c(1:3)

# Shiny Dashboardに載せられるように整形する。
matrix_to_pick_comparison = matrix(0, nrow = length(ranking_of_ipwe), ncol = max(range_of_Fi))
for(fi in range_of_Fi){
  matrix_to_pick_comparison[, fi] =
    unlist(lapply(detect_colname_of_Fi,
                  function(x){ifelse(identical(gsub(paste0("F", fi, "."), "", x[grep(paste0("F", fi, "."), x)]), character(0)),
                                     "Not selected",
                                     gsub(paste0("F", fi, "."), "", x[grep(paste0("F", fi, "."), x)])
                  )}
    ))
}
midflow_dataframe_to_pick_comparison = as.data.frame(matrix_to_pick_comparison)
range_of_colname_Fi = c(2:4)
colnames(midflow_dataframe_to_pick_comparison) = colnames(dat.raw)[range_of_colname_Fi]
range_of_choice_Fi = c(1:3)
dataframe_to_pick_comparison = as.data.frame( apply(midflow_dataframe_to_pick_comparison, 2, function(x){gsub("\\.", " ", x)}) )

# 縮退の有無を明記する。
Fallbacked = ifelse(identical(grep("fallback", batch4rank), integer(0)),
                    rep("No", length(batch4rank)),
                    rep("Yes", length(batch4rank))
)
dataframe_to_pick_comparison$Fallbacked = Fallbacked

# 選択番号を表示する。
nrow_of_dataframe_to_pick_comparison = nrow(dataframe_to_pick_comparison)
const_of_all_zero = 1 # 比較対象を選ばないときを先頭にするための定数
`Selectable number` = c(1:nrow_of_dataframe_to_pick_comparison) + const_of_all_zero
dataframe_to_pick_comparison = cbind(`Selectable number`, dataframe_to_pick_comparison)


# 選択画面の設計 #
tabPanel_of_Comparison =
  tabPanel("",
           h4("Input value described in Available Combinations.
              When zero is input, comparisons are not conducted."),
           br(),
           fluidRow(
             column(4, style = list("padding-right: 5px;"),
                    numericInput("1st_Comparison",
                                label = "1st", 
                                value = 1,
                                min = 1,
                                max = nrow_of_dataframe_to_pick_comparison + const_of_all_zero)
             ),
             column(4, style = list("padding-right: 5px;"),
                    numericInput("2nd_Comparison",
                                label = "2nd", 
                                value = 1,
                                min = 1,
                                max = nrow_of_dataframe_to_pick_comparison + const_of_all_zero)
             ),
             column(4, style = list("padding-right: 5px;"),
                    numericInput("3rd_Comparison",
                                label = "3rd", 
                                value = 1,
                                min = 1,
                                max = nrow_of_dataframe_to_pick_comparison + const_of_all_zero)
             )
           )
  )