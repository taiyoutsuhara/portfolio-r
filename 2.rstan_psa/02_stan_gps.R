## GPSの推定 ##

# サービスの種類を目的変数、属性質問を説明変数とする  #
# 多項ロジスティック回帰モデルによりGPSを推定する。   #
dat4gps = read.fst(batch4gps[ba])

# 目的変数、説明変数の用意
# 目的変数はnumericに型変換しないと、stanでエラーになる。
obj_var_of_gps = dat4gps[, grep("Q4", colnames(dat4gps))]
obj_var_of_gps_numeric = as.numeric(obj_var_of_gps)
exp_vars_of_gps = dat4gps[, -grep("CustomerID|Q4|Q5", colnames(dat4gps))]

# 区別の付くカテゴリの除外@説明変数
regex_for_exp.vars_distinguishable = "F1.Senior|F2.South|F3.Others"
ifelse_of_1st_and_2nd = ifelse(is.na(list_of_exception_colnames[[ba]][2]), list_of_exception_colnames[[ba]][1], list_of_exception_colnames[[ba]][2])
ifelse_of_1st_to_3rd = ifelse(is.na(list_of_exception_colnames[[ba]][3]), ifelse_of_1st_and_2nd, list_of_exception_colnames[[ba]][3])
regex_for_exp.vars_for_splits = paste(list_of_exception_colnames[[ba]][1], ifelse_of_1st_and_2nd, ifelse_of_1st_to_3rd, sep = "|")
regex_for_exp.vars_exception = paste(regex_for_exp.vars_distinguishable, regex_for_exp.vars_for_splits, sep = "|")
trim_exp_vars_of_gps = exp_vars_of_gps[, grep(regex_for_exp.vars_exception, colnames(exp_vars_of_gps), invert = T)]

# 全部0の説明変数を除外
check_for_nrow_equal_zero = apply(trim_exp_vars_of_gps, 2, sum)
names_of_nrow_is_larger_than_zero = names(check_for_nrow_equal_zero[check_for_nrow_equal_zero != 0])
inclusion_relation_between_colnames_and_names = colnames(trim_exp_vars_of_gps) %in% names_of_nrow_is_larger_than_zero
complete_exp_vars_of_gps = trim_exp_vars_of_gps[, inclusion_relation_between_colnames_and_names]


# Stanの実行 #
# stanに入力するパラメータとデータを用意する。
Intercept = rep(1, nrow(dat4gps)) # 切片用データ
intercept_and_explanatory_variables = cbind(Intercept, complete_exp_vars_of_gps)
data_for_stan_gps = list(N = nrow(dat4gps), # データ数
                         D = 1 + ncol(complete_exp_vars_of_gps), # 切片と説明変数の数
                         K = length_of_ServiceType, # 目的変数のカテゴリ数
                         X = cbind(Intercept, complete_exp_vars_of_gps), # 切片と説明変数
                         Y = obj_var_of_gps_numeric) # 目的変数

# 実際に推定し、推定結果要約を書き出す。
stan4gps = stan("gps_zero.stan",
                data = data_for_stan_gps,
                seed = seed_number, # 乱数種の指定
                iter = 2000, # サンプリング回数
                warmup = 1000, # バーンイン数。初期の推定状態は不安定ゆえカット
                thin = 2, # 何個おきに結果を採択するか。
                chains = 4, # iter回行うサンプリングを何回するか。
                algorithm = "NUTS") # No U-Turn Sampler (NUTS)
coes_of_gps = summary(stan4gps)
data_frame_of_coes = as.data.frame(coes_of_gps$summary)
write.csv(data_frame_of_coes, write4gps_summary[ba], row.names = T, quote = F)

# Rhat < 1.05を満足すれば、以下の処理を実行する。 #
TF_count_of_Rhat = table(na.omit(data_frame_of_coes$Rhat) < 1.05)
conditional_branching_for_writing =
  ifelse(!names(TF_count_of_Rhat) %in% "FALSE",
         TF_count_of_Rhat[names(TF_count_of_Rhat) == "TRUE"] == length(data_frame_of_coes$Rhat),
         FALSE)
if(TF_count_of_Rhat[names(TF_count_of_Rhat) == "FALSE"] == 0){
  # 推定された目的変数を取り出し、一般化傾向スコアを計算する。
  range_of_exp_var_nums = c(1:length_of_ServiceType)
  row_names_of_coes = row.names(data_frame_of_coes)
  row_name_pattern = obj_var_nums = obj_coes = exp_list = list()
  gps_list = NULL
  for(l in range_of_exp_var_nums){
    # 対応する説明変数の行番号を取り出す。
    fix_pattern = "mu[[0-9]?[0-9]?[0-9]?[0-9]?[0-9]?[0-9],"
    row_name_pattern[[l]] = paste0(fix_pattern, l, "]")
    obj_var_nums[[l]] = grep(row_name_pattern[[l]], row_names_of_coes)
    # 該当する推定済目的変数を取り出す。
    obj_coes[[l]] = data_frame_of_coes$mean[obj_var_nums[[l]]]
    # 式exp(α + Σβx)を作成する。
    exp_list[[l]] = exp(obj_coes[[l]])
  }
  
  # 一般化傾向スコアを計算する。
  data_frame_of_exp_list = as.data.frame(exp_list)
  sum_exp = apply(data_frame_of_exp_list, 1, sum)
  gps = as.data.frame(lapply(exp_list, function(x){x / sum_exp}))
  colnames(gps) = paste0("GPS_", levels_of_ServiceType)
  dat4csp = cbind(dat4gps, gps)
  
  # コモンサポートを満足するデータのみを採択する。          #
  # 他グループと全く重複しない傾向スコアの除外が目的である。#
  descstat4csp = describeBy(gps, obj_var_of_gps)
  val_of_min_gps = max(unlist(lapply(descstat4csp, function(x){x$`min`})))
  val_of_max_gps = min(unlist(lapply(descstat4csp, function(x){x$`max`})))
  TF_of_csp = apply(gps >= val_of_min_gps & gps <= val_of_max_gps, 1, function(x){all(x == rep(T, length_of_ServiceType))})
  dat_satisfied_csp = dat4csp[TF_of_csp, ]
  
  
  # IPW計算用生データの作成 #
  # 1.コモンサポート満足済データ数が、大元の生データ数の閾値以上か。
  TF_regarding_to_nrow_of_dat_satisfied_csp = (nrow(dat_satisfied_csp) >= nrow(dat.raw) * val.th4csp)
  
  # 2.サービスの種類F（サービスを受けていない。）が全サービスの10%以上を占めているか。
  # IPWのインフレーションを回避するため、本制約を適用する。
  TF_ipw_not_inflation =
    length( dat_satisfied_csp$`Q4.ServiceType`[dat_satisfied_csp$`Q4.ServiceType` == levels_of_ServiceType[length_of_ServiceType]] ) >=
    length(dat_satisfied_csp$`Q4.ServiceType`) * val.th4inflation
  
  # 3.サービスを利用していない（F）を除き、全種類存在するか。
  table_of_servicetype = table(levels(unique(dat_satisfied_csp$`Q4.ServiceType`)) %in% levels_of_ServiceType[-length_of_ServiceType])
  value_that_servicetype_includes_all_the_others = ifelse(length(table_of_servicetype) == 2, table_of_servicetype[names(table_of_servicetype) == "TRUE"], 0)
  TF_servicetype_includes_all_the_others = (value_that_servicetype_includes_all_the_others == (length_of_ServiceType - 1))
  
  # 4.条件1を満足しないとき、コモンサポート満足済データ数が0ではない。
  TF_nrow_of_dat_satisfied_csp_is_not_zero = (nrow(dat_satisfied_csp) > 0)
  
  # 条件1～4を満足するかどうかでデータを書き出すか、書き出さないかを分岐する。
  if(TF_regarding_to_nrow_of_dat_satisfied_csp &
     TF_ipw_not_inflation &
     TF_servicetype_includes_all_the_others &
     TF_nrow_of_dat_satisfied_csp_is_not_zero){
    write.fst(dat_satisfied_csp, write4gps[ba])
  }else if(TF_ipw_not_inflation &
           TF_servicetype_includes_all_the_others &
           TF_nrow_of_dat_satisfied_csp_is_not_zero){
    write.fst(dat_satisfied_csp, write4fallback[ba])
  }else{
    # 書き出さない。
  }
}