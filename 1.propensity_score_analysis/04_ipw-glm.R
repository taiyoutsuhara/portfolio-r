## IPWEの計算 ##

# 利用額を目的変数、サービスの種類を説明変数とし、IPWを付与した  #
# 一般化線形モデルによりIPWEを計算する。なお、切片は推定しない。 #
dat4ipwe = read.fst(batch4ipwe[ba])
obj_var_of_ipwe = dat4ipwe$`Q5.CustomerDollar`
exp_var_of_ipwe = dat4ipwe$`Q4.ServiceType`
ipw = dat4ipwe$IPW
glm4ipwe = glm(obj_var_of_ipwe ~ . - 1, data = exp_var_of_ipwe, weights = ipw)
results_of_ipwe = summary(glm4ipwe)


# 推定結果の書出し #
# 逸脱残差
dat4ipwe$deviance.resid = results_of_ipwe$deviance.resid
write.fst(dat4ipwe, write4ipwe[ba])

# 各種係数
func.extract_coefficients_of_ipwe_or_glm(results_of_ipwe,
                                         write4coes[ba],
                                         c(1:length_of_ServiceType),
                                         levels_of_ServiceType)
func.extract_misc_of_ipwe_or_glm(results_of_ipwe, write4misc[ba])