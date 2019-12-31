## IPWの計算 ##

dat4ipw = read.fst(batch4ipw[ba])
dat4ipw.gps = dat4ipw[, grep("GPS", colnames(dat4ipw))]

length_of_eachtype = table(dat4ipw$`Q4.ServiceType`)
dat4ipw$`IPW` = rep(0, nrow(dat4ipw))
for(num.type in 1:length(levels_of_ServiceType)){
  dat4ipw$`IPW`[dat4ipw$`Q4.ServiceType` == levels_of_ServiceType[num.type]] =
    (1/dat4ipw.gps[dat4ipw$`Q4.ServiceType` == levels_of_ServiceType[num.type], num.type]) *
    (sum(length_of_eachtype) / length_of_eachtype[num.type])
}

write.fst(dat4ipw, write4ipw[ba])