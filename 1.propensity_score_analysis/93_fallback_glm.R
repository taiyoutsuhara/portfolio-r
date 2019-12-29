## 縮退時、一般化線形モデルによるサービス導入効果の推定 ##

# 利用額を目的変数、サービスの種類を説明変数とする一般化線形モデル #
# によりサービス導入効果を推定する。なお、切片は推定しない。       #
dat4glm = read.fst(batch4glm[ba])
obj.var.glm = dat4glm$`Q5.CustomerDollar`
exp.var.glm = dat4glm$`Q4.ServiceType`
glm4fallback = glm(obj.var.glm ~ . - 1, data = exp.var.glm)
res.fallback = summary(glm4fallback)

# 推定結果の書出し #
# 逸脱残差
dat4fallback$deviance.resid = res.fallback$deviance.resid
write.fst(dat4fallback, write4fallback)


# 各種係数
func.extract_coefficients_of_ipwe_or_glm(dat4ipwe, write4coes.fallback[ba])
func.extract_misc_of_ipwe_or_glm(dat4misc, write4misc.fallback[ba])