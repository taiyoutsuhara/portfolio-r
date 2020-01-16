## Stanで一般化傾向スコアと因果効果*を推定する。 * 縮退時はサービス導入効果 ##

# ライブラリ #
# 初回時のみ、RStanを除き必要なライブラリをインストールする。
installed_packages_list = library()
installed_package_names = installed_packages_list$results[, 1] # 1列目にPackage名がある。
required_packages = c("caret", "data.table", "DT", "fst", "psych", "scales", "shiny",
                      "shinydashboard", "tidyverse", "VGAM")
packages_not_installed = required_packages[required_packages %in% installed_package_names == F]
identical_character_not_zero = !identical(packages_not_installed, character(0))
if(identical_character_not_zero){
  install.packages(packages_not_installed, dependencies = T)
}

# 読込み
library(caret)
library(data.table)
library(DT)
library(fst)
library(psych)
library(scales)
library(shiny)
library(shinydashboard)
library(tidyverse)
library(VGAM)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)


# ディレクトリ設定 #
dir.origin = paste0(getwd(), "/1.propensity_score_analysis/")
dir.main = paste0(getwd(), "/2.rstan_psa/")
setwd(dir.main)
dirs.sub = list("stan_gps", "stan_gps_estimation", "stan_ipw", "stan_ipw-glm")

# 必要なサブディレクトリを作成
require.dirs.sub = paste0(paste(unlist(dirs.sub), collapse = "$|"), "$")
whether.dirs.sub = grep(require.dirs.sub, list.files()) # サブディレクトリを探す。
no.dirs.sub = identical(whether.dirs.sub, integer(0)) # サブディレクトリが皆無
if(no.dirs.sub){
  lapply(dirs.sub, function(x){dir.create(paste0(getwd(), "/", x))})
}

# サブディレクトリのフルパスを取得。バッチ処理(batch4hoge)時使用のため。
detect.dirs.sub = list.files(full.names = T)
dirs.sub.full = detect.dirs.sub[grep(require.dirs.sub, detect.dirs.sub)]


# 自作関数の読込みと乱数種の指定 #
source(paste0(dir.origin, "99_myfunctions_psa.R"), encoding = "UTF-8")
set.seed(12345)
seed_number = 12345 # stanの乱数種指定で使用

# 分析用データに整形する処理 #
dat.raw = fread(paste0(dir.origin, "demorawdata.csv"),
                data.table = F,
                stringsAsFactors = F,
                encoding = "UTF-8",
                sep = ",")

# ダミーデータ取出し用グローバル変数
colnum_of_Age = grep("Age", colnames(dat.raw))
dat_of_Age = dat.raw[, colnum_of_Age]
colnum_of_Region = grep("Region", colnames(dat.raw))
dat_of_Region = dat.raw[, colnum_of_Region]
colnum_of_Occupation = grep("Occupation", colnames(dat.raw))
dat_of_Occupation = dat.raw[, colnum_of_Occupation]

# サービスの種類用グローバル変数
levels_of_ServiceType = levels(as.factor(dat.raw$`Q4.ServiceType`))
length_of_ServiceType = length(levels_of_ServiceType)

# 各種コード表の読込み
code_of_region = fread(paste0(dir.origin, "attachments/", "Code_table_of_Prefectures_and_Regions.csv"),
                       data.table = F,
                       stringsAsFactors = F,
                       encoding = "UTF-8",
                       sep = ",") # 47都道府県、地方区分のコード
levels_of_region = unique(code_of_region[, c(3:4)])
code_of_occupation = fread(paste0(dir.origin, "attachments/", "Code_table_of_Occupations.csv"),
                           data.table = F,
                           stringsAsFactors = F,
                           encoding = "UTF-8",
                           sep = ",") # 職業のコード
levels_of_occupation = code_of_occupation$Category
descriptions_of_occupation = code_of_occupation$Occupation

# 各種パラメータ
min.age = 20
max.age = 70
ran.regions = c(1:6)
ran.occupations = c(1:5)
percentile.age = c(0, 1/3, 2/3, 1)
character.age = c("Young", "Middle", "Senior")
YES = 1 # カテゴリに該当するとき、1を割り当てる。
NO  = 0 # カテゴリに該当しないとき、0を割り当てる。
ran.age        = c(1:3)
ran.region     = c(4:9)
ran.occupation = c(10:14)
const_of_ran.region_transform = 3     # レンジを変更するための変数
const_of_ran.occupation_transform = 9 # 同上
len.age        = length(ran.age)
len.region     = length(ran.region)
len.occupation = length(ran.occupation)


# 一般化傾向スコア（GPS）の推定 #
# dataformatから入力ファイルリストを読み込む。
subdir.dataformat = paste0(dir.origin, "dataformat/")
batch4gps = list.files(subdir.dataformat, full.names = T)

# 出力ファイルリストのサブディレクトリをstan_gpsに指定する。
subdir.origin = "1.propensity_score_analysis/dataformat/"
subdir.gps = paste0("2.rstan/", dirs.sub[[1]], "/stan_gps_")
write4gps      = gsub(subdir.origin, subdir.gps, batch4gps)
write4gps_summary     = gsub("stan_gps/stan_gps", "stan_gps_estimation/stan_gps_summary", write4gps)
write4gps_summary     = gsub(".fst", ".csv", write4gps_summary)
write4fallback = gsub("stan_gps/stan_gps", "stan_gps/stan_fallback", write4gps)

# 必要なグローバル変数を定義する。
val.th4csp = 0.001 # IPW計算用生データ作成条件1で使用する閾値
val.th4inflation = 0.1 # 同上条件2で使用する閾値
list_of_exception_colnames = strsplit(gsub(".fst", "", list.files(subdir.dataformat)), "_")
for(ba in 1:length(batch4gps)){
  source("02_stan_gps.R", encoding = "utf-8")
}


# 逆確率重み（IPW）の計算 #
batch4ipw_glm = list.files(dirs.sub.full[1], full.names = T)
batch4ipw  = batch4ipw_glm[grep("/stan_gps/stan_gps", batch4ipw_glm)]
write4ipw  = gsub("/stan_gps/stan_gps", "/stan_ipw/stan_ipw", batch4ipw)
for(ba in 1:length(batch4ipw)){
  source(paste0(dir.origin, "03_ipw.R"), encoding = "utf-8")
}


# 縮退時、一般化線形モデルによるサービス導入効果の推定 #
batch4glm = batch4ipw_glm[grep("/stan_gps/stan_fallback", batch4ipw_glm)]
write4glm = gsub("/stan_gps/stan_fallback", "/stan_ipw-glm/stan_glm", batch4glm)
write4summary.fallback = gsub("fst", "csv",
                           gsub("stan_ipw-glm/stan_glm", "stan_ipw-glm/stan_fallback_summary", write4glm)
                           )
write4coes.fallback = gsub("fst", "csv",
                           gsub("stan_ipw-glm/stan_glm", "stan_ipw-glm/stan_fallback_coes", write4glm)
                           )
if(!identical(batch4glm, character(0))){ # 縮退時だけ実行する。
  for(ba in 1:length(batch4glm)){
    source("93_stan_fallback_glm.R", encoding = "utf-8")
  }
}


# IPW推定量（IPWE）の計算 #
batch4ipwe = list.files(dirs.sub.full[2], full.names = T)
write4ipwe = gsub("stan_ipw/stan_ipw", "stan_ipw-glm/stan_ipw-glm", batch4ipwe)
write4summary = gsub("fst", "csv", gsub("stan_ipw-glm/stan_ipw-glm", "stan_ipw-glm/stan_summary", write4ipwe) )
write4coes = gsub("fst", "csv", gsub("stan_ipw-glm/stan_ipw-glm", "stan_ipw-glm/stan_coes", write4ipwe) )
for(ba in 1:length(batch4ipwe)){
  source("04_stan_ipw-glm.R", encoding = "utf-8")
}