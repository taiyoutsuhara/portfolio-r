## GPSの推定 ##

# サービスの種類を目的変数、属性質問を説明変数とする #
# 多項ロジスティック回帰モデルによりGPSを推定する。  #
dat4gps = read.fst(batch4gps[ba])

# 目的変数、説明変数の用意
obj_var_of_gps  = dat4gps[, grep("Q4", colnames(dat4gps))]
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

# 推定、GPSの取出し
lrm4gps = vglm(obj_var_of_gps ~ ., data = complete_exp_vars_of_gps, family = "multinomial")
gps = as.data.frame(fitted(lrm4gps))
colnames(gps) = paste0("GPS_", colnames(gps))
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
  length( dat_satisfied_csp$`Q4.ServiceType`[dat_satisfied_csp$`Q4.ServiceType` == levels_of_ServiceType[length_of_ServiceType]] ) >= length(dat_satisfied_csp$`Q4.ServiceType`) * val.th4inflation

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