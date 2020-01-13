# R言語による技術の棚卸し #
成果物（2020/1/12時点）は以下のとおりです。各々の詳細は、該当のMarkdownを参照してください。

文体を次のように統一しています。
* 敬体：本ドキュメント
* 常体：各成果物のMarkdown

### 実行手順
実行環境にRとRStudioがインストールされていることを前提とします。

RStudioでリポジトリのクローン先となるProjectを作成します。プロジェクト名とリポジトリ名とを揃えておくと便利です。Projectを作成すると、Rprojファイルがあるディレクトリをワーキングディレクトリとして認識します。

クローン先を用意した後、以下の手順を実行します。
* Gitを使用の場合：クローン先のディレクトリにおいて`git clone`コマンドを実行します。Sourcetree等のGUIクライアントでも同機能があります。
* そうでない場合：`Clone or download`の`Download ZIP`をクリックし、クローン先のディレクトリに展開します。  

Rのライブラリで足りないものを、あらかじめインストールします。

### 1.propensity_score_analysis
サービス比較システムであり、本システムの特色は次の2点です。
1. 一般化傾向スコア分析によるサービス導入効果の予測
1. Shiny Dashboardによるサービス比較の容易化

詳細は下記Markdownにまとめています。  
https://github.com/taiyoutsuhara/portfolio-r/blob/master/1.propensity_score_analysis/readme_ja.md

### 2.rstan_psa
`1.propensity_score_analysis`の一般化傾向スコア、逆確率重みづけ推定量、ならびにサービス導入効果（縮退時）を、Stanによって推定します。Stanとはベイズ推定によってパラメータを推定するフリーソフトです。

詳細は下記Markdownにまとめています。  
https://github.com/taiyoutsuhara/portfolio-r/blob/master/2.rstan_psa/readme_stan.md

##### 注意事項
Stan実行時に並列演算をさせていますが、並列化しない場合、RStanを最新版にアップデートしてください。
```
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
```
RStanのアップデート方法は、以下のURLを参照してください。  
https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started-(Japanese)

Stanによる一般化傾向スコアの推定に、時間が非常にかかります※。また、収束しないことが往々にしてあります。  
※PCのスペックに依存しますが、おおよその目安は**最短半日**です。