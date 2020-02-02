# サービス比較システム #
## あらまし
本システムで対応する技術的課題は次の2点である。

1. 効果推定の問題  
介入群（例：サービス利用者）と対照群（例：非利用者）とで共通に得られる変数を両群で不偏にしないと、効果を正しく推定できない。この手続きを共変量調整というが、共変量数に対し調整する組み合わせ数が指数的に増加し、そのまま調整することは非現実である。そこで共変量を、介入群と対照群の所属確率を表す1つの変数に縮約し、それを基に共変量調整する手法が確立されている。この変数を傾向スコアといい、介入群が多群のとき一般化傾向スコアという。
本システムでは、一般化傾向スコア分析で共変量を調整し上記の問題に対処する。

1. レポーティングの問題  
レポーティングはビジネスインテリジェンスツールのほか、Officeスイート（例えば、Excel）によることがある。しかし、後者に次の問題がある。①OSは実質Windows一択（特にVBA使用時）である。②大規模データの処理は非現実的である。③ソースコードがバイナリに組み込まれており、管理する手間が大きい。
そこで、本システムではShiny Dashboardを採用し、Officeスイートの問題点に対処する。 

そこで、本システムでは次の2点を目的とし、技術的課題の解決を図る。

1. 一般化傾向スコア分析によるサービス導入効果の予測
1. Shiny Dashboardによるサービス比較の容易化

システム設計における工夫点は次の4点である。

1. コモンサポート※により、介入群（サービス利用者）と対照群（非利用者）とが重ならないデータをカットし、データの厳密性を向上  
※一般化傾向スコアが介入群と対照群の両群で重なり合っている領域
1. コモンサポートを満足するデータが閾値以下のとき、一般化線形モデル（GLM）により介入効果を予測するよう、縮退ルーチンを用意
1. 逆確率重みづけ推定量（IPWE）の計算により、回帰係数の差が検討可能
1. Shiny Dashboard上にサービス比較と予測結果の可視化を一体化

また、次のニーズがあると仮定して、各サブルーチンを実装している。

1. 早急に予想を知り戦略のアウトラインを大まかに書きたい。  
→（本システム）予測結果出力機能（cf. 93_fallback_glm.R, 04_ipw-glm.R）、Shiny Dashboard
1. 2種類以上のサービスの優先順位が付けがたく、慎重を期したい。  
→（本システム）2種類以上のサービス比較（cf. サンプルデータ）
1. ターゲット（年代、居住地方、職業等の属性）別に、メリット最大化できそうなサービスの目星を付けたい。  
→（本システム）大元の分析データをターゲット別に分割する機能（cf. 01_dataformat.R）
1. 複数属性（例えば若年×東日本×学生）に有効なサービスも予想できるとうれしい。  
→（本システム）同上

## Shiny Dashboardのイメージ
今回、ユーザインタフェース（UI）にタブパネルを採用し、次のコンポーネントを含む。
* Information：各サービスの概要
* Comparison：比較したい属性と選択可能パターン表
* Visualization：Comparisonで選んだ属性における予測結果のグラフ。グラフ内をダブルクリックすると、該当する点の情報（Double-clicked point）を得られる。

起動するとInformationが開く。ここでは、各サービスの概要が記されている。
![information](dashboard_image/information.png)
Comparisonで比較したい属性を選択する。下の例では選択可能パターン表に、比較したい属性の番号（Selectable number）、年代、居住地方、職業、縮退の有無がまとまっている。"Not selected"は、該当属性による分析データ分割がないことを意味する。入力フォームにSelectable numberを入力すると、最大3種類属性間比較ができる。
![comparison_initial](dashboard_image/comparison_initial.png)
Visualizationに、選んだ属性別予測結果がグラフ化される。下のように、初期状態では何も比較されない。
![visualization_initial](dashboard_image/visualization_initial.png)
属性を分けないとき（全体。Selectable number = 2）の分析結果だけ見たい場合を想定する。このときの使用例として、年代、居住地方、職業のいずれにも依存しそうにないサービス※戦略の選定が挙げられる。  
※このようなサービスは、希有ではないかと推測する。
![visualization_1_item](dashboard_image/visualization_1_item.png)
次に、中年層（Selectable number = 3）をターゲットとしたとき、メリットを最大化できそうなサービス戦略の予想を想定する。下のように、メリット最大化できそうなサービスが、全体と中年層とで異なっていることが判る。
![visualization_2_items](dashboard_image/visualization_2_items.png)
最後に、中年層と老年層（Selectable number = 5）とで、サービス戦略を変えた方が良いのかどうか判断に迷っている場合を考えてみる。下のグラフだけで判断すると、サービス戦略を変えると若干プラスになると予想される。
![visualization_3_items](dashboard_image/visualization_3_items.png)

## サンプルデータ
サービス満足度に関するWebアンケートで、<img src="https://latex.codecogs.com/gif.latex?\inline&space;n&space;=&space;10,000" title="n = 10,000" />件のデータを得たと仮定する。この仮想のデータが"demorawdata.csv"である。

本データの項目は以下のとおりである。
##### 属性
F1.年齢：20～70歳  
F2.居住都道府県：47都道府県  
F3.職業：学生、民間企業職員、公的機関職員、教育関係職員、その他
##### 質問
Q1.前回の弊サービス利用有無：はい、いいえ  
Q2.前回の弊サービス利用額：円  
Q3.弊社サービス改善の認知：はい、いいえ  
Q4.今回弊サービスで利用したもの：A, B, C, D, E。利用していない（F）  
Q5.今回の弊サービス利用額：円

## ルーチンの概要
メインルーチンは"00_main.R"であり、サブルーチン実行だけでなく、各サブルーチンで使用するグローバル変数も定義している。

各ルーチンで使用するデータの構造仕様書は、サブディレクトリ
"/data_structure_specifications/"を参照のこと。
* spec.raw_data.csv
* spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv
* spec.coes_of_ipw-glm.csv
* spec.misc_of_ipw-glm.csv
* spec.table_of_available_combinations.csv
* spec.data_frame_for_ggplot2.csv

フローチャートは以下の通りである。フロートチャート内のプレフィックス"R"は、縮退を意味する。
![flowchart](https://raw.githubusercontent.com/taiyoutsuhara/portfolio-r/develop/fix_docs/1.propensity_score_analysis/flowchart.png?raw=true)

### 01_dataformat.R
分析用データの整形と、整形済データの属性別分割をする。分割前のデータ構造仕様は"spec.raw_data.csv"のとおりである。

まず、属性を次のダミーデータに変換し、変換済の属性と質問とを結合する。結合後のデータ構造仕様は、"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"のとおりであるが、この時点では20列目までしか存在しない。
##### F1.年齢
分位数によって次の3水準に縮約する。
- 若年
- 中年
- 老年
##### F2.居住都道府県
次の6地方に縮約する。
- 北日本：北海道、青森県～福島県（東北地方）
- 東日本：茨城県～神奈川県（関東地方）
- 中日本：新潟県～愛知県（中部地方）
- 西日本のうち近畿：三重県～兵庫県
- 西日本のうち近畿以西：岡山県～高知県（中国・四国地方）
- 南日本：福岡県～鹿児島県（九州地方）、沖縄県
##### F3.職業
- 学生
- 民間企業職員
- 公的機関職員
- 教育関係職員
- その他

先の整形済データを属性別に分割するが、次の4条件を満足すれば分割済データを出力する。
1. カテゴリの列番号が属性のそれに含まれているか。
1. 分割済データの行数が、整形済データのそれをカテゴリ数で割ったもの以上か。
1. サービスの種類に「サービスを利用していない。」を表すカテゴリを含むか。
1. その他のカテゴリを全て含むか。

### 02_estimate_gps.R
各データの識別番号を<img src="https://latex.codecogs.com/gif.latex?\inline&space;k(k&space;=&space;1,&space;2,&space;\cdots,&space;K)" title="k(k = 1, 2, \cdots, K)" />、各サービスの識別番号を<img src="https://latex.codecogs.com/gif.latex?\inline&space;i(i&space;=&space;1,&space;2,&space;\cdots,&space;I)" title="i(i = 1, 2, \cdots, I)" />、共変量（F1ダミー、F2ダミー、F3ダミー、Q1, Q2, Q3）を<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{x}_{jk}&space;\&space;(j&space;=&space;1,&space;2,&space;\cdots,&space;J)" title="\mathbf{x}_{jk} \ (j = 1, 2, \cdots, J)" />、一般化傾向スコアを<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{e}_{ik}" title="\mathbf{e}_{ik}" />とする。このとき、次の多項ロジスティック回帰モデルにより一般化傾向スコアを推定する。

<div align = "center">
<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{e}_{ik}&space;=&space;\dfrac{\exp&space;(\boldsymbol{\alpha}_{ik}&space;&plus;&space;\sum_{j&space;=&space;1}^{J}&space;\boldsymbol{\beta}_{ik}^{j}\mathbf{x}_{jk})}{\sum_{i=1}^{I}&space;\exp&space;(\boldsymbol{\alpha}_{ik}&space;&plus;&space;\sum_{j&space;=&space;1}^{J}&space;\boldsymbol{\beta}_{ik}^{j}\mathbf{x}_{jk})}" title="\mathbf{e}_{ik} = \dfrac{\exp (\boldsymbol{\alpha}_{ik} + \sum_{j = 1}^{J} \boldsymbol{\beta}_{ik}^{j}\mathbf{x}_{jk})}{\sum_{i=1}^{I} \exp (\boldsymbol{\alpha}_{ik} + \sum_{j = 1}^{J} \boldsymbol{\beta}_{ik}^{j}\mathbf{x}_{jk})}" />
</div>

なお、次の変数は<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{x}_{jk}" title="\mathbf{x}_{jk}" />に代入しない。
* 老年、南日本、その他（他のカテゴリで区別できるため。）
* 全部0の共変量
* 全部1の共変量（但し、Q2を除く。）

推定後、コモンサポート（<img src="https://latex.codecogs.com/gif.latex?\inline&space;\max(\min(\mathbf{e}_{1k},&space;\cdots,&space;\mathbf{e}_{Ik}))&space;\leq&space;\mathbf{e}_{ik}&space;\leq&space;\min(\max(\mathbf{e}_{1k},&space;\cdots,&space;\mathbf{e}_{Ik}))" title="\max(\min(\mathbf{e}_{1k}, \cdots, \mathbf{e}_{Ik})) \leq \mathbf{e}_{ik} \leq \min(\max(\mathbf{e}_{1k}, \cdots, \mathbf{e}_{Ik}))" />）を満足するデータのみを採択する。ここで、コモンサポートとは、一般化傾向スコアが介入群と対照群の両群で重なり合っている領域のことである。本手続きにより、分析データの厳密性を向上させる。

確認後、次の4条件を満足すればIPW計算用生データを作成する。
1. コモンサポート満足済データの行数が、大元の生データの閾値以上か。
1. サービスの種類F（サービスを受けていない。）が全サービスの10%以上を占めているか。IPWのインフレーションを回避するため、本制約を適用する。
1. サービスを利用していない（F）を除き、全種類存在するか。
1. 条件1を満足しないとき、コモンサポート満足済データ数が0ではない。

4条件を満足しないとき、次のように場合分けする。
* 2, 3, 4番を満足するとき、縮退用一般化線形モデル（GLM）用データを作成する。
* そのほかの場合、データを作成しない。

このときのデータ構造仕様は、"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"のうち次の列を結合したものである。
* 1列目
* 2列目～20列目のうち、多項ロジスティック回帰モデルの説明変数に代入したもの
* 21列目～26列目

### 03_ipw.R
データ別総件数を<img src="https://latex.codecogs.com/gif.latex?\inline&space;n^{\prime}_{k}" title="n^{\prime}_{k}" />、サービスの種類別件数を<img src="https://latex.codecogs.com/gif.latex?\inline&space;n^{\prime}_{ik}" title="n^{\prime}_{ik}" />、IPWを<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{w}_{ik}" title="\mathbf{w}_{ik}" />とおく。このとき、IPWは次の式により計算できる。

<div align = "center">
<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{w}_{ik}&space;=&space;\dfrac{1}{\mathbf{e}_{ik}}&space;\times&space;\dfrac{n^{\prime}_{k}}{n^{\prime}_{ik}}" title="\mathbf{w}_{ik} = \dfrac{1}{\mathbf{e}_{ik}} \times \dfrac{n^{\prime}_{k}}{n^{\prime}_{ik}}" />
</div>

IPWを結合し、IPWE-GLM用データを作成する。このときのデータ構造仕様は、
"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"のうち次の列を結合したものである。
* 1列目
* 2列目～20列目のうち、多項ロジスティック回帰モデルの説明変数に代入したもの
* 21列目～27列目

### 93_fallback_glm.R
「Q5.今回の弊サービス利用額」を<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{y}_{ik}" title="\mathbf{y}_{ik}" />、「Q4.今回弊サービスで利用したもの」を<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{z}_{ik}" title="\mathbf{z}_{ik}" />、サービス導入効果を<img src="https://latex.codecogs.com/gif.latex?\inline&space;\boldsymbol{\gamma^{\prime}}_{ik}" title="\boldsymbol{\gamma^{\prime}}_{ik}" />とする。コモンサポートを満足するデータが閾値以下のとき、次のGLMによって<img src="https://latex.codecogs.com/gif.latex?\inline&space;\boldsymbol{\gamma^{\prime}}_{ik}" title="\boldsymbol{\gamma^{\prime}}_{ik}" />を推定する。

<div align = "center">
<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{y}_{ik}&space;=&space;\sum_{i&space;=&space;1}^{I}&space;\boldsymbol{\gamma}_{ik}^{\prime}\mathbf{z}_{ik}" title="\mathbf{y}_{ik} = \sum_{i = 1}^{I} \boldsymbol{\gamma}_{ik}^{\prime}\mathbf{z}_{ik}" />
</div>

推定後、IPWE-GLM用データに逸脱残差を結合する。このときのデータ構造仕様は、
"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"のうち次の列を結合したものである。
* 1列目
* 2列目～20列目のうち、多項ロジスティック回帰モデルの説明変数に代入したもの
* 21列目～28列目

また、推定結果を"spec.coes_of_ipw-glm.csv"と"spec.misc_of_ipw-glm.csv"のとおり整形してから、書き出す。

### 04_ipw-glm.R
サービス導入効果の大きさを表す因果効果<img src="https://latex.codecogs.com/gif.latex?\inline&space;E(\mathbf{y}_{ik})&space;-&space;E(\mathbf{y}_{0k})" title="E(\mathbf{y}_{ik}) - E(\mathbf{y}_{0k})" />を、次の一般化線形モデルによって推定する。

<div align = "center">
<img src="https://latex.codecogs.com/gif.latex?\inline&space;\mathbf{y}_{ik}&space;=&space;\sum_{i&space;=&space;1}^{I}&space;(\boldsymbol{\gamma}_{ik}\mathbf{z}_{ik})&space;\mathbf{w}_{ik},&space;\text{where}\&space;E(\mathbf{y}_{ik})&space;=&space;\boldsymbol{\gamma}_{ik},&space;\&space;E(\mathbf{y}_{0k})&space;=&space;\boldsymbol{\gamma}_{Ik}" title="\mathbf{y}_{ik} = \sum_{i = 1}^{I} (\boldsymbol{\gamma}_{ik}\mathbf{z}_{ik}) \mathbf{w}_{ik}, \text{where}\ E(\mathbf{y}_{ik}) = \boldsymbol{\gamma}_{ik}, \ E(\mathbf{y}_{0k}) = \boldsymbol{\gamma}_{Ik}" />
</div>

推定後のデータ書き出し処理は、"93_fallback_glm.R"と同様である。

### 05-1_ui.R
Shiny Dashboardによって、因果効果の大小を比較し図化する。次のパーツによってShiny Dashboardを作成する。

* サービスの種類と概要を表示する。@ 05-1_ui_info.R
* 比較したいサービスを選択するタブパネル。3種類比較できるようにしている。@ 05-1_ui_tabPanel_of_comparison.R
* タブパネルと選択可能パターン表を表示する。@ 05-1_ui_comparison.R
* データ分割×グループ別因果効果※をグラフ化する。@ 05-1_ui_ranking.R
※縮退時はサービス導入効果<img src="https://latex.codecogs.com/gif.latex?\inline&space;\boldsymbol{\gamma^{\prime}}_{ik}" title="\boldsymbol{\gamma^{\prime}}_{ik}" />
* Shiny Dashboardを描画する。@ 05-1_ui_to_render.R

選択可能パターン表、グラフ描画用データフレームの構造仕様はそれぞれ、
"spec.table_of_available_combinations.csv"、"spec.data_frame_for_ggplot2.csv"
のとおりである。

### 05-2_server.R
server関数に入出力データを格納し、UIオブジェクトとserver関数を引数として、アプリケーションを実行する。

### 99_myfunctions_psa.R
共通化できる処理を集約するため、次の自作関数を定義している。

* 連続値（例：年齢）からダミーデータを作成する関数
* 整形データ分割用関数
* GLM, IPWE-GLMの結果を取り出す関数
* ggplot2用データフレーム作成関数