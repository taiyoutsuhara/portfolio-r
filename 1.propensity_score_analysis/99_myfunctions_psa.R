## サブルーチンで使用する自作関数 ##
## 処理のまとまりの最適化が目的   ##

# 連続値（例：年齢）からダミーデータを作成する関数 #
func.make_dummy_from_continuous_data = function(Compared_Object,
                                                Baseline,
                                                range_of_age,
                                                Prefix_of_Category,
                                                Character_of_Age,
                                                Val_of_YES,
                                                Val_of_NO,
                                                nrow_of_raw){
  for(cell in range_of_age){
    new_variable = paste0(Prefix_of_Category, ".", Character_of_Age[cell])
    formula_of_ifelse = "ifelse(Compared_Object >= Baseline[cell] & Compared_Object < Baseline[cell + 1], rep(Val_of_YES, nrow_of_raw), rep(Val_of_NO, nrow_of_raw))"
    eval(parse(text = paste0(new_variable, "<<-", formula_of_ifelse)))
  }
}


# 整形データ分割用関数。次の4条件を満足すれば処理を実行する。 #
# 1. カテゴリの列番号が属性のそれに含まれているか。
# 2. 分割済データの行数が、整形済データのそれをカテゴリ数で割ったもの以上か。
# 3. サービスの種類に「サービスを利用していない。」を表すカテゴリを含むか。
# 4. その他のカテゴリを全て含むか。
func.split_rawdata = function(dat_of_n_target,
                              baseline_of_nrow,
                              range_dat_of_n_target,
                              colnumber_of_F1, colnumber_of_F2, colnumber_of_F3,
                              length_of_F1, length_of_F2, length_of_F3,
                              service_levels, length_of_service_levels,
                              colnumber_of_ServiceType){
  for(list in range_dat_of_n_target){
    # 条件1
    TF_regarding_to_range_dat_of_n_target_in_F1 = (list %in% colnumber_of_F1)
    TF_regarding_to_range_dat_of_n_target_in_F2 = (list %in% colnumber_of_F2)
    TF_regarding_to_range_dat_of_n_target_in_F3 = (list %in% colnumber_of_F3)
    
    # 条件2
    TF_regarding_to_nrow_of_split_data_in_F1 = (nrow(dat_of_n_target[[list]]) >=  baseline_of_nrow / length_of_F1)
    TF_regarding_to_nrow_of_split_data_in_F2 = (nrow(dat_of_n_target[[list]]) >=  baseline_of_nrow / length_of_F2)
    TF_regarding_to_nrow_of_split_data_in_F3 = (nrow(dat_of_n_target[[list]]) >=  baseline_of_nrow / length_of_F3)
    
    # 条件3
    table_of_no_service = table(unique(dat_of_n_target[[list]][, colnumber_of_ServiceType]) %in% service_levels[length_of_ServiceType])
    value_of_no_service = ifelse(length(table_of_no_service) == 2, table_of_no_service[names(table_of_no_service) == "TRUE"], 0)
    TF_regarding_to_ServiceTypes_include_no_service = (value_of_no_service == 1)
    
    # 条件4
    table_of_others = table(unique(dat_of_n_target[[list]][, colnumber_of_ServiceType]) %in% service_levels[-length_of_ServiceType])
    value_of_others = ifelse(length(table_of_others) == 2, table_of_others[names(table_of_no_service) == "TRUE"], 0)
    TF_regarding_to_ServiceTypes_include_the_others = (value_of_others == (length_of_service_levels - 1))
    
    # 条件1～4を満足するかどうかで条件分岐
    if(TF_regarding_to_range_dat_of_n_target_in_F1 &
       TF_regarding_to_nrow_of_split_data_in_F1 &
       TF_regarding_to_ServiceTypes_include_no_service &
       TF_regarding_to_ServiceTypes_include_the_others){
      write.fst(dat_of_n_target[[list]],
                paste0(dirs.sub.full[1], "/", names(dat_of_n_target)[list], ".fst"))
    }else if(TF_regarding_to_range_dat_of_n_target_in_F2 &
             TF_regarding_to_nrow_of_split_data_in_F2 &
             TF_regarding_to_ServiceTypes_include_no_service &
             TF_regarding_to_ServiceTypes_include_the_others){
      write.fst(dat_of_n_target[[list]],
                paste0(dirs.sub.full[1], "/", names(dat_of_n_target)[list], ".fst"))
    }else if(TF_regarding_to_range_dat_of_n_target_in_F3 &
             TF_regarding_to_nrow_of_split_data_in_F3 &
             TF_regarding_to_ServiceTypes_include_no_service &
             TF_regarding_to_ServiceTypes_include_the_others){
      write.fst(dat_of_n_target[[list]],
                paste0(dirs.sub.full[1], "/", names(dat_of_n_target)[list], ".fst"))
    }else{
      # not write
    }
  }
}

# AND条件が最大のときに使用する関数
func.split_rawdata_maxcombinations = function(dat_of_n_target,
                                              baseline_of_nrow,
                                              range_dat_of_n_target,
                                              length_of_Fs,
                                              service_levels, length_of_service_levels,
                                              colnumber_of_ServiceType){
  for(list in range_dat_of_n_target){
    # 条件2
    TF_regarding_to_nrow_of_split_data_in_Fs = (nrow(dat_of_n_target[[list]]) >=  baseline_of_nrow / length_of_Fs)
    
    # 条件3
    table_of_no_service = table(unique(dat_of_n_target[[list]][, colnumber_of_ServiceType]) %in% service_levels[length_of_ServiceType])
    value_of_no_service = ifelse(length(table_of_no_service) == 2, table_of_no_service[names(table_of_no_service) == "TRUE"], 0)
    TF_regarding_to_ServiceTypes_include_no_service = (value_of_no_service == 1)
    
    # 条件4
    table_of_others = table(unique(dat_of_n_target[[list]][, colnumber_of_ServiceType]) %in% service_levels[-length_of_ServiceType])
    value_of_others = ifelse(length(table_of_others) == 2, table_of_others[names(table_of_others) == "TRUE"], 0)
    TF_regarding_to_ServiceTypes_include_the_others = (value_of_others == (length_of_service_levels - 1))
    
    # 条件2～4を満足するかどうかで条件分岐
    if(TF_regarding_to_nrow_of_split_data_in_Fs &
       TF_regarding_to_ServiceTypes_include_no_service &
       TF_regarding_to_ServiceTypes_include_the_others){
      write.fst(dat_of_n_target[[list]],
                paste0(dirs.sub.full[1], "/", names(dat_of_n_target)[list], ".fst"))
    }else{
      # not write
    }
  }
}


# GLM, IPWE-GLMの結果を取り出す関数 #
func.extract_coefficients_of_ipwe_or_glm = function(results_of_ipwe_glm,
                                                    batch_of_write4coes,
                                                    range_of_service_levels,
                                                    service_levels){
  res.coes = as.data.frame(results_of_ipwe_glm$coefficients)
  num.col_of_coes_primitive = 4
  for(n.add in range_of_service_levels){
    res.coes[, n.add + num.col_of_coes_primitive] = res.coes$Estimate - res.coes$Estimate[n.add]
    colnames(res.coes)[n.add + num.col_of_coes_primitive] = paste0("diff.data_", service_levels[n.add])
  }
  res.coes = cbind(res.coes, results_of_ipwe_glm$cov.scaled, results_of_ipwe_glm$cov.unscaled)
  colnames(res.coes) = c(colnames(res.coes)[c(1:(num.col_of_coes_primitive + max(range_of_service_levels)))],
                         paste0("cov.scaled.", colnames(results_of_ipwe$cov.scaled)),
                         paste0("cov.unscaled.", colnames(results_of_ipwe$cov.unscaled)))
  fwrite(res.coes, batch_of_write4coes, row.names = T, sep = ",", quote = F)
}
func.extract_misc_of_ipwe_or_glm = function(results_of_ipwe_glm, batch_of_write4misc){
  res.misc = as.data.frame(c("dispersion" = results_of_ipwe_glm$dispersion,
                             "null.deviance" = results_of_ipwe_glm$null.deviance,
                             "df.null" = results_of_ipwe_glm$df.null,
                             "deviance" = results_of_ipwe_glm$deviance,
                             "df.residual" = results_of_ipwe_glm$df.residual,
                             "aic" = results_of_ipwe_glm$aic,
                             "iter" = results_of_ipwe_glm$iter))
  colnames(res.misc) = "misc"
  fwrite(res.misc, batch_of_write4misc, row.names = T, sep = ",", quote = F)
}


# ggplot2用データフレーム作成関数 #
make_dataframe_for_ggplot2 = function(outcome_vector, ordinal_number_of_comparison){
  data.frame("Outcome" = outcome_vector,
             "Service Type" = levels_of_ServiceType[-length_of_ServiceType],
             "Comparison" = ordinal_number_of_comparison
  )
}