## メインルーチン ##

# ライブラリ読込み #
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


# ディレクトリ設定 #
dir.main = paste0(getwd(), "/1.propensity_score_analysis/")
setwd(dir.main)
dirs.sub = list("dataformat", "gps", "ipw", "ipw-glm")

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
source(paste0(getwd(), "/99_myfunctions_psa.R"), encoding = "UTF-8")
set.seed(12345)

# 分析用データに整形する処理 #
dat.raw = fread(paste0(dir.main, "demorawdata.csv"),
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
code_of_region = fread(paste0(getwd(), "/attachments/", "Code_table_of_Prefectures_and_Regions.csv"),
                       data.table = F,
                       stringsAsFactors = F,
                       encoding = "UTF-8",
                       sep = ",")
levels_of_region = unique(code_of_region[, c(3:4)])
code_of_occupation = fread(paste0(getwd(), "/attachments/", "Code_table_of_Occupations.csv"),
                           data.table = F,
                           stringsAsFactors = F,
                           encoding = "UTF-8",
                           sep = ",")
levels_of_occupation = code_of_occupation$Category
descriptions_of_occupation = code_of_occupation$Occupation

# 各種パラメータ
min.age = 20
max.age = 70
ran.regions = c(1:6)
ran.occupations = c(1:5)
percentile.age = c(0, 1/3, 2/3, 1)
character.age = c("Young", "Middle", "Senior")
YES = 1
NO  = 0
ran.age        = c(1:3)
ran.region     = c(4:9)
ran.occupation = c(10:14)
const_of_ran.region_transform = 3
const_of_ran.occupation_transform = 9
len.age        = length(ran.age)
len.region     = length(ran.region)
len.occupation = length(ran.occupation)

# データ整形の実行
source("01_dataformat.R", encoding = "utf-8")


# 一般化傾向スコア（GPS）の推定 #
batch4gps = list.files(dirs.sub.full[1], full.names = T)
write4gps      = gsub("dataformat/", paste0(dirs.sub[[2]], "/gps_"), batch4gps)
write4fallback = gsub("gps/gps", "gps/fallback", write4gps)
val.th4csp = 0.001 # 1 out of 1000 regard to nrow of reshape data
val.th4inflation = 0.1
list_of_exception_colnames = strsplit(gsub(".fst", "", list.files(dirs.sub.full[1])), "_")
for(ba in 1:length(batch4gps)){
  source("02_estimate_gps.R", encoding = "utf-8")
}


# 逆確率重み（IPW）の計算 #
batch4ipw_glm = list.files(dirs.sub.full[2], full.names = T)
batch4ipw  = batch4ipw_glm[grep("/gps/gps", batch4ipw_glm)]
write4ipw  = gsub("/gps/gps", "/ipw/ipw", batch4ipw)
for(ba in 1:length(batch4ipw)){
  source("03_ipw.R", encoding = "utf-8")
}


# 縮退時、一般化線形モデルによるサービス導入効果の推定 #
batch4glm = batch4ipw_glm[grep("/gps/fallback", batch4ipw_glm)]
write4glm = gsub("/gps/fallback", "/ipw-glm/glm", batch4glm)
write4coes.fallback = gsub("fst", "csv", gsub("ipw-glm/glm", "ipw-glm/fallback_coes", write4glm) )
write4misc.fallback = gsub("fst", "csv", gsub("ipw-glm/glm", "ipw-glm/fallback_misc", write4glm) )
if(!identical(batch4glm, character(0))){ # 縮退時だけ実行する。
  for(ba in 1:length(batch4glm)){
    source("93_fallback_glm.R", encoding = "utf-8")
  }
}


# IPW推定量（IPWE）の計算 #
batch4ipwe = list.files(dirs.sub.full[3], full.names = T)
write4ipwe = gsub("ipw/ipw", "ipw-glm/ipw-glm", batch4ipwe)
write4coes = gsub("fst", "csv", gsub("ipw-glm/ipw-glm", "ipw-glm/coes", write4ipwe) )
write4misc = gsub("fst", "csv", gsub("ipw-glm/ipw-glm", "ipw-glm/misc", write4ipwe) )
for(ba in 1:length(batch4ipwe)){
  source("04_ipw-glm.R", encoding = "utf-8")
}


# Shiny Dashboardによる推定結果の可視化 #
batch4output = list.files(dirs.sub.full[4], full.names = T)
batch4rank = batch4output[grep("coes", batch4output)]
code_of_service = fread(paste0(dir.main, "/attachments/", "Code_table_of_Service_Types.csv"),
                        stringsAsFactors = F,
                        encoding = "UTF-8",
                        sep = ",")
source("05-1_ui.R", encoding = "utf-8")
source("05-2_server.R", encoding = "utf-8")
shinyApp(ui, server)