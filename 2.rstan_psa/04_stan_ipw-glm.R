## IPWEの計算 ##

# 利用額を目的変数、サービスの種類を説明変数とし、IPWを付与した  #
# 一般化線形モデルによりIPWEを計算する。なお、切片は推定しない。 #
dat4ipwe = read.fst(batch4ipwe[ba])
obj_var_of_ipwe = dat4ipwe$`Q5.CustomerDollar`
exp_var_of_ipwe = dat4ipwe$`Q4.ServiceType`
numeric_var_of_ipwe = as.numeric(exp_var_of_ipwe)
ipw = dat4ipwe$IPW

# 説明変数を0, 1のダミー変数に変換する。
dummy_var_of_ipwe = list()
range_of_dummy = c(1:length_of_ServiceType)
for(ld in range_of_dummy){
  dummy_var_of_ipwe[[ld]] = ifelse(numeric_var_of_ipwe  == ld, 1, 0)
}
names(dummy_var_of_ipwe) = levels_of_ServiceType
dummy_var_of_ipwe = as.data.frame(dummy_var_of_ipwe)

# Stanの実行 #
# stanに入力するパラメータとデータを用意する。
data_for_stan_ipwe = list(N = nrow(dat4ipwe), # データ数
                          M = ncol(dummy_var_of_ipwe), # 説明変数の数
                          X = dummy_var_of_ipwe, # 説明変数
                          Y = obj_var_of_ipwe, # 目的変数
                          W = ipw) # 重み

# 実際に推定し、推定結果要約を書き出す。
stan4ipwe = stan("ipwe.stan",
                 data = data_for_stan_ipwe,
                 seed = seed_number, # 乱数種の指定
                 iter = 2000, # サンプリング回数
                 warmup = 1000, # バーンイン数。初期の推定状態は不安定ゆえカット
                 thin = 2, # 何個おきに結果を採択するか。
                 chains = 4, # iter回行うサンプリングを何回するか。
                 algorithm = "NUTS") # No U-Turn Sampler (NUTS)
coes_of_ipwe = summary(stan4ipwe)
data_frame_of_coes = as.data.frame(coes_of_ipwe$summary)
write.csv(data_frame_of_coes, write4summary[ba], row.names = T, quote = F)


# Rhat < 1.05を満足すれば、以下の処理を実行する。 #
TF_count_of_Rhat = table(na.omit(data_frame_of_coes$Rhat) < 1.05)
conditional_branching_for_writing =
  ifelse(!names(TF_count_of_Rhat) %in% "FALSE",
         TF_count_of_Rhat[names(TF_count_of_Rhat) == "TRUE"] == length(data_frame_of_coes$Rhat),
         FALSE)
if(conditional_branching_for_writing){
  # 因果効果、因果効果の標準誤差を取り出す。
  num_of_mu = grep("mu", row.names(data_frame_of_coes))
  mean_of_ipwe = data_frame_of_coes$mean[num_of_mu]
  se_of_ipwe = data_frame_of_coes$se_mean[num_of_mu]
  ipwe_table = describeBy(mean_of_ipwe, group = exp_var_of_ipwe)
  se_ipwe_table = describeBy(se_of_ipwe, group = exp_var_of_ipwe)
  
  # 係数をまとめる
  ipwe_estimation = unlist(lapply(ipwe_table, function(x){x$mean}))
  se_estimation = unlist(lapply(se_ipwe_table , function(x){x$mean}))
  ipwe_diff = as.data.frame(matrix(0, nrow = length_of_ServiceType, ncol = length_of_ServiceType))
  for(n.add in range_of_dummy){
    ipwe_diff[, n.add] = ipwe_estimation - ipwe_estimation[n.add]
    colnames(ipwe_diff)[n.add] = paste0("diff.data_", levels_of_ServiceType[n.add])
  }
  
  # 推定した係数を書き出す。
  stan_coes_of_ipwe = cbind(ipwe_estimation, se_estimation, ipwe_diff)
  colnames(stan_coes_of_ipwe)[c(1:2)] = c("Estimate", "Std. Error")
  write.csv(stan_coes_of_ipwe, write4coes, row.names = T, quote = F)
}