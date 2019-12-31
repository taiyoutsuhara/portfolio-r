## 大元の生データを分析用データに整形 ##

# ダミーデータの作成 #
# 年齢：不等式「閾値_(cell) ≦ 年齢 < 閾値_(cell+1)」の閾値に分位数を代入し、
# 若年、中年、老年に分ける。なお、左端は最年少、右端は最年長に1を加えた値である。
quantiles_of_age = quantile(dat_of_Age, percentile.age)
quantiles_of_age = c(min.age, quantiles_of_age[c(2:(length(quantiles_of_age) - 1))], max.age + 1)
func.make_dummy_from_continuous_data(dat_of_Age,
                                     quantiles_of_age,
                                     ran.age,
                                     "F1",
                                     character.age,
                                     YES,
                                     NO,
                                     nrow(dat.raw))
F1.Splits = cbind(F1.Young, F1.Middle, F1.Senior)

# 地方区分
region_split = list()
attach(code_of_region)
for(list_of_region in ran.regions){
  region_split[[list_of_region]] = PrefCode[Region %in% levels_of_region[list_of_region, 2]]
  names(region_split)[list_of_region] = levels_of_region[list_of_region, 2]
}
detach(code_of_region)
`F2.Splits` = lapply(region_split, function(x){ifelse(dat_of_Region %in% x, YES, NO)})
names(`F2.Splits`) = paste0("F2.", names(region_split))
F2.Splits = as.data.frame(F2.Splits)

# 職業
occupation_split = list()
attach(code_of_occupation)
for(list_of_occupation in ran.occupations){
  occupation_split[[list_of_occupation]] = Category[Category %in% levels_of_occupation[list_of_occupation]]
  names(occupation_split)[list_of_occupation] = descriptions_of_occupation[list_of_occupation]
}
detach(code_of_occupation)
`F3.Splits` = lapply(occupation_split, function(x){ifelse(dat_of_Occupation == x, YES, NO)})
names(`F3.Splits`) = paste0("F3.", names(occupation_split))
F3.Splits = as.data.frame(F3.Splits)

# (YES, NO) = (1, 2) を (YES, NO) = (1, 0)に振り直す。@ Q1, Q3
dat.raw$`Q1.HaveEverUsed`[dat.raw$`Q1.HaveEverUsed` == 2] = NO
dat.raw$`Q3.Well-known`[dat.raw$`Q3.Well-known` == 2] = NO


# 分析用データに整形する。 #
attach(dat.raw) # to cut rename colnames
dat.reshaped = cbind(CustomerID,
                     F1.Splits,
                     F2.Splits,
                     F3.Splits,
                     Q1.HaveEverUsed,
                     Q2.FormerCustomerDollar,
                     `Q3.Well-known`,
                     Q4.ServiceType,
                     Q5.CustomerDollar)
detach(dat.raw)
dat.reshaped = as.data.frame(dat.reshaped)
write.fst(dat.reshaped, paste0(dirs.sub.full[1], "/dat.entire.fst"))




## 整形データをカテゴリ別に分割 ##

# 分割用TFベクトルを作成 #
# 1条件
dat4splits = dat.reshaped[, grep("F1|F2|F3", colnames(dat.reshaped))]
TF4_1t = (dat4splits == YES)

# 2条件
TF4_2t = list()
for(col.tf4_1t in c(ran.age, ran.region)){
  if(col.tf4_1t <= max(ran.age)){
    TF4_2t[[col.tf4_1t]] = TF4_1t[, col.tf4_1t] & TF4_1t[, -ran.age]
  }else{
    TF4_2t[[col.tf4_1t]] = TF4_1t[, col.tf4_1t] & TF4_1t[, -c(ran.age, ran.region)]
  }
  colnames(TF4_2t[[col.tf4_1t]]) = paste0(colnames(TF4_1t)[col.tf4_1t], # TF4splits[, col.tf4_1t]
                                          "_",
                                          colnames(TF4_2t[[col.tf4_1t]])
                                          )
}
TF4_2t = as.data.frame(TF4_2t)

# 3条件
TF4_3t = list()
TF4_2t3t = TF4_2t[, grep("F1.*_F2", colnames(TF4_2t))]
for(col.tf4_2t3t in ran.occupation){
  TF4_3t[[col.tf4_2t3t - const_of_ran.occupation_transform]] = TF4_2t3t & TF4_1t[, col.tf4_2t3t]
  colnames(TF4_3t[[col.tf4_2t3t - const_of_ran.occupation_transform]]) =
    paste0(colnames(TF4_3t[[col.tf4_2t3t - const_of_ran.occupation_transform]]),
           "_",
           colnames(TF4_1t)[col.tf4_2t3t]
    )
}
TF4_3t = as.data.frame(TF4_3t)

# TFベクトルにより整形データを分割
dat.1target = apply(TF4_1t, 2, function(x){dat.reshaped[x,]})
dat.2targets = apply(TF4_2t, 2, function(x){dat.reshaped[x,]})
dat.3targets = apply(TF4_3t, 2, function(x){dat.reshaped[x,]})


# 分割済データの書出し
colnumber_of_F1only = grep("F1", names(dat.1target))
colnumber_of_F2only = grep("F2", names(dat.1target))
colnumber_of_F3only = grep("F3", names(dat.1target))
colnumber_of_F1_and_F2 = grep("F1.*_F2", names(dat.2targets))
colnumber_of_F1_and_F3 = grep("F1.*_F3", names(dat.2targets))
colnumber_of_F2_and_F3 = grep("F2.*_F3", names(dat.2targets))
func.split_rawdata(dat.1target,
                   nrow(dat.reshaped),
                   c(1:ncol(TF4_1t)),
                   colnumber_of_F1only,
                   colnumber_of_F2only,
                   colnumber_of_F3only, 
                   length(colnumber_of_F1only),
                   length(colnumber_of_F2only),
                   length(colnumber_of_F3only),
                   levels_of_ServiceType,
                   length_of_ServiceType,
                   19)
func.split_rawdata(dat.2targets,
                   nrow(dat.reshaped),
                   c(1:ncol(TF4_2t)),
                   colnumber_of_F1_and_F2,
                   colnumber_of_F1_and_F3,
                   colnumber_of_F2_and_F3, 
                   (length(colnumber_of_F1only) * length(colnumber_of_F2only)),
                   (length(colnumber_of_F1only) * length(colnumber_of_F3only)),
                   (length(colnumber_of_F2only) * length(colnumber_of_F3only)),
                   levels_of_ServiceType,
                   length_of_ServiceType,
                   19)
func.split_rawdata_maxcombinations(dat.3targets,
                                   nrow(dat.reshaped),
                                   c(1:ncol(TF4_3t)),
                                   (length(colnumber_of_F1only) * length(colnumber_of_F2only) * length(colnumber_of_F3only)),
                                   levels_of_ServiceType,
                                   length_of_ServiceType,
                                   19)