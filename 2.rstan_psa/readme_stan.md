# Stanによるベイズ推定 #
## あらまし
`1.propensity_score_analysis`の一般化傾向スコア、逆確率重みづけ推定量（IPWE）、ならびにサービス導入効果（縮退時）を、Stanによって推定する。数式の定義や推定後の手続き等は、`1.propensity_score_analysis`のMarkdownを参照のこと。

https://github.com/taiyoutsuhara/portfolio-r/blob/master/1.propensity_score_analysis/readme_ja.md

Stanとはベイズ推定によってパラメータを推定するフリーソフトである。内部では乱数生成アルゴリズム（No-U-Turn Sampler (NUTS)\*）が使用されている。  
\* マルコフ連鎖モンテカルロ（MCMC）法の一種であるハミルトニアンモンテカルロ（HMC）法を、発展させたアルゴリズム。サンプルが同じところに戻ってきたら、サンプリングを止めることにより、計算量を削減している。

RとStanとの間で、次の連携を取っている。

![sequence_stan](https://raw.githubusercontent.com/taiyoutsuhara/portfolio-r/develop/rstan_psa/routines/2.rstan_psa/sequence_rstan.png?raw=true)


## ルーチンの概要
メインルーチンは"02-04_estimation_with_stan.R"であり、サブルーチン実行だけでなく、各サブルーチンで使用するグローバル変数も定義している。

各ルーチンで使用するデータの構造仕様書は、サブディレクトリ
"/data_structure_specifications/" ("/./") を参照のこと。
* /1.propensity_score_analysis/./spec.coes_of_ipw-glm.csv
* /2.stan_psa/./spec.summary_of_gps.csv
* /2.stan_psa/./spec.summary_of_ipw-glm.csv

Stanによる推定に関するフローチャートは、以下のとおりである。なお、Stanを使用するフローのプレフィックスに"S"を付けており、フロー別番号は`1.propensity_score_analysis`のフローチャートに合わせている。

![flowchart_stan](https://raw.githubusercontent.com/taiyoutsuhara/portfolio-r/develop/rstan_psa/routines/2.rstan_psa/flowchart_rstan.png?raw=true)

### 02_stan_gps.R, gps_zero.stan
このサブルーチンは、`1.propensity_score_analysis/02_estimate_gps.R`に対応する。

gps_zero.stanによって一般化傾向スコアを推定する。Stanの実装にあたって、識別可能性を考慮するため、「サービスを利用していない」カテゴリ選択の強さを0に固定している。固定化によって、残りのサービスの種類を選択する強さを、固定したカテゴリとの比較で決められるようにする。

Stan実行時のパラメータは次のように設定しており、`fallback_glm.stan`と`ipwe.stan`においても同様に設定する。

* seed = 12345 (seed_number)
* iter = 2000
* warmup = 1000
* chains = 4
* thin = 2

推定が終わったら、推定結果要約（stan_gps_summary_hoge.csv）を書き出す。本要約のデータ構造仕様書はspec.summary_of_gps.csvのとおりである。

推定結果要約を書き出した後、全パラメータにおいてRhat < 1.05を満足するかどうかを確認する。Rhat値はチェーンが定常収束しているかどうかを判断する指標の一つである。この手続きは次のサブルーチンでも実行する。

* 93_stan_fallback_glm.R
* 04_stan_ipw-glm.R

定常収束判断後の手続きは、`1.propensity_score_analysis/02_estimate_gps.R`と同様である。

### 93_stan_fallback_glm.R, fallback_glm.stan
このサブルーチンは、`1.propensity_score_analysis/93_fallback_glm.R`に対応する。

fallback_glm.stanによってサービス導入効果を推定し、推定結果要約（stan_fallback_summary_hoge.csv）を書き出す。本要約のデータ構造仕様はspec.summary_of_ipw-glm.csvのとおりである。

定常収束を判断した後、推定した係数をstan_fallback_coes_hoge.csvに書き出す。本CSVのデータ構造仕様は"/1.propensity_score_analysis/./spec.coes_of_ipw-glm.csv"から、t value, Pr(>|t|), cov.scaled, cov.unscaledを除いたものである。

### 04_stan_ipw-glm.R, ipwe.stan
このサブルーチンは、`1.propensity_score_analysis/04_ipw-glm.R`に対応する。

ipwe.stanによって因果効果を推定し、推定結果要約（stan_summary_hoge.csv）を書き出す。本要約のデータ構造仕様はspec.summary_of_ipw-glm.csvのとおりである。

定常収束を判断した後、推定した係数をstan_coes_hoge.csvに書き出す。本CSVのデータ構造仕様は、stan_fallback_coes_hoge.csvと同様である。