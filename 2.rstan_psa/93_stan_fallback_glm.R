## 縮退時、一般化線形モデルによるサービス導入効果の推定 ##

# 利用額を目的変数、サービスの種類を説明変数とする。 #
# によりサービス導入効果を推定する。なお、切片は推定しない。       #
dat4glm = read.fst(batch4glm[ba])
obj_var_of_glm = dat4glm$`Q5.CustomerDollar`
exp_var_of_glm = dat4glm$`Q4.ServiceType`
numeric_var_of_glm = as.numeric(exp_var_of_glm)

# 説明変数を0, 1のダミー変数に変換する。
dummy_var_of_glm = list()
range_of_dummy = c(1:length_of_ServiceType)
for(ld in range_of_dummy){
  dummy_var_of_glm[[ld]] = ifelse(numeric_var_of_glm  == ld, 1, 0)
}
names(dummy_var_of_glm) = levels_of_ServiceType
dummy_var_of_glm = as.data.frame(dummy_var_of_glm)


# Stanで推定する。 #
# stanに入力するパラメータとデータを用意する。
data_for_stan_glm = list(N = nrow(dat4glm), # データ数
                         M = ncol(exp_var_of_glm), # 説明変数の数
                         X = dummy_var_of_glm, # 説明変数
                         Y = obj_var_of_glm) # 目的変数

# 実際に推定し、推定結果要約を書き出す。
stan4glm = stan("fallback_glm.stan",
                data = data_for_stan_glm,
                seed = seed_number, # 乱数種の指定
                iter = 2000, # サンプリング回数
                warmup = 1000, # バーンイン数。初期の推定状態は不安定ゆえカット
                thin = 2, # 何個おきに結果を採択するか。
                chains = 4, # iter回行うサンプリングを何回するか。
                algorithm = "NUTS") # No U-Turn Sampler (NUTS)
coes_of_glm = summary(stan4glm)
data_frame_of_coes = as.data.frame(coes_of_ipwe$summary)
write.csv(data_frame_of_coes, write4summary.fallback[ba], row.names = T, quote = F)


# Rhat < 1.05を満足すれば、以下の処理を実行する。 #
TF_count_of_Rhat = table(na.omit(data_frame_of_coes$Rhat) < 1.05)
if(TF_count_of_Rhat[names(TF_count_of_Rhat) == "FALSE"] == 0){
  # 推定結果、推定結果の標準誤差を取り出す。
  num_of_mu = grep("mu", row.names(data_frame_of_coes))
  mean_of_glm = data_frame_of_coes$mean[num_of_mu]
  se_of_glm = data_frame_of_coes$se_mean[num_of_mu]
  glm_table = describeBy(mean_of_glm, group = exp_var_of_glm)
  se_glm_table = describeBy(se_of_glm, group = exp_var_of_glm)
  
  # 係数をまとめる
  glm_estimation = unlist(lapply(glm_table, function(x){x$mean}))
  se_estimation = unlist(lapply(se_glm_table , function(x){x$mean}))
  glm_diff = as.data.frame(matrix(0, nrow = length_of_ServiceType, ncol = length_of_ServiceType))
  for(n.add in range_of_dummy){
    glm_diff[, n.add] = glm_estimation - glm_estimation[n.add]
    colnames(glm_diff)[n.add] = paste0("diff.data_", levels_of_ServiceType[n.add])
  }
  
  # 推定した係数を書き出す。
  stan_coes_of_glm = cbind(glm_estimation, se_estimation, glm_diff)
  colnames(stan_coes_of_glm)[c(1:2)] = c("Estimate", "Std. Error")
  write.csv(stan_coes_of_glm, write4coes.fallback, row.names = T, quote = F)
}