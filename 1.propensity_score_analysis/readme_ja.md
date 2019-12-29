# サービス比較システム #
## あらまし
本システムで対応する課題は次の2点である。

1. 効果推定の問題
介入群（例：サービス利用者）と対照群（例：非利用者）とで共通に得られる変数を両群で不偏にしないと、効果を正しく推定できない。この手続きを共変量調整というが、共変量数に対し調整する組み合わせ数が指数的に増加し、そのまま調整することは非現実である。そこで共変量を、介入群と対照群の所属確率を表す1つの変数に縮約し、それを基に共変量調整する手法が確立されている。この変数を傾向スコアといい、介入群が多群のとき一般化傾向スコアという。
本システムでは、一般化傾向スコア分析で共変量を調整し上記の問題に対処する。

1. レポーティングの問題
レポーティングはビジネスインテリジェンスツールのほか、Officeスイート（例えば、Excel）によることがある。しかし、後者に次の問題がある。①OSは実質Windows一択である。②大規模データの処理は非現実的である。③ソースコードがバイナリに組み込まれており、管理する手間が大きい。
そこで、本システムではShiny Dashboardを採用し、Officeスイートの問題点に対処する。 

そこで、本システムでは次の2点を目的とし、課題解決を図る。

1. 一般化傾向スコア分析によるサービス利用効果の予測
1. Shiny Dashboardによるサービス比較の容易化

システム設計における工夫点は次の4点である。

1. コモンサポート※により、介入群（サービス利用者）と対照群（非利用者）とが重ならないデータをカットし、データの厳密性を向上
※一般化傾向スコアが介入群と対照群の両群で重なり合っている領域
1. コモンサポートを満足するデータが閾値以下のとき、一般化線形モデル（GLM）により介入効果を予測するよう、縮退ルーチンを用意
1. 逆確率重みづけ推定量（IPWE）の計算により、回帰係数の差が検討可能
1. Shiny Dashboard上にサービス比較と予測結果の可視化を一体化


## サンプルデータ
サービス満足度に関するWebアンケートで、$n = 10,000$件のデータを得たと仮定する。本データの項目は以下のとおりである。
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

フローチャートは最後に掲載している。

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
1. 上記を除き、1種類以上のサービスを含むか。

### 02_estimate_gps.R
「Q4.今回弊サービスで利用したもの」を$\mathbf{z}_{i} \ (i = 1, 2, \cdots, I)$、ダミーデータをそれぞれ$\mathbf{x}_{j} \ (j = 1, 2, \cdots, J)$、一般化傾向スコアを$\mathbf{e}_{i}$とする。このとき、次の多項ロジスティック回帰モデルにより一般化傾向スコアを推定する。なお、老年、南日本、その他は他のカテゴリで区別できるので、$\mathbf{x}_{j}$に代入しない。
$$
\mathbf{e}_{i} = \dfrac{\exp (\boldsymbol{\alpha}_{i} + \sum_{j = 1}^{J} \boldsymbol{\beta}_{i}^{j}\mathbf{x}_{j})}{\mathbf{1} + \exp (\boldsymbol{\alpha}_{j} + \sum_{j = 1}^{J} \boldsymbol{\beta}_{j}\mathbf{x}_{j})}
$$

推定後、コモンサポート（$\max(\min(\mathbf{e}_{1}, \cdots, \mathbf{e}_{I})) \leq \mathbf{e}_{i} \leq \min(\max(\mathbf{e}_{1}, \cdots, \mathbf{e}_{I}))$）を満足するデータのみを採択する。ここで、コモンサポートとは、一般化傾向スコアが介入群と対照群の両群で重なり合っている領域のことである。本手続きにより、分析データの厳密性を向上させる。

確認後、次の4条件を満足すればIPW計算用生データを作成する。このときのデータ構造仕様は、"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"の1～26列目のとおりである。
1. コモンサポート満足済データの行数が、大元の生データの閾値以上か。
1. サービスの種類F（サービスを受けていない。）が全サービスの10%以上を占めているか。IPWのインフレーションを回避するため、本制約を適用する。
1. サービスを利用していない（F）を除き、サービスの種類が1つ以上存在するか。
1. 条件1を満足しないとき、コモンサポート満足済データ数が1件以上である。

4条件を満足しないとき、次のように場合分けする。
* 2, 3, 4番を満足するとき、縮退用一般化線形モデル（GLM）用データを作成する。
* そのほかの場合、データを作成しない。

### 03_ipw.R
サービスの種類別件数を$n^{\prime}_{k} (k = 1, 2, \cdots, K)$、IPWを$\mathbf{w}_{i}$とおく。このとき、IPWは次の式により計算できる。
$$
\mathbf{w}_{i} = \dfrac{1}{\mathbf{e}_{i}} \times \dfrac{n}{n^{\prime}_{k}}
$$

IPWを結合し、IPWE-GLM用データを作成する。このときのデータ構造仕様は
"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"の1～27列目のとおりである。

### 93_fallback_glm.R
コモンサポートを満足するデータが閾値以下のとき、次のGLMによってサービス導入効果$\boldsymbol{\gamma}_{i}$を推定する。
$$
\mathbf{y}_{i} = \sum_{i = 1}^{I} \boldsymbol{\gamma}_{i}^{\prime}\mathbf{z}_{i}
$$
ここで、$\mathbf{y}_{i}$に「Q5.今回の弊サービス利用額」を代入する。

推定後、IPWE-GLM用データに逸脱残差を結合する。このときのデータ構造仕様は、"spec.reshaped_data_binding_gps_ipw_and_deviance.resid.csv"のとおりである。

また、推定結果を"spec.coes_of_ipw-glm.csv"と"spec.misc_of_ipw-glm.csv"のとおり整形してから、書き出す。

### 04_ipw-glm.R
サービス導入効果の大きさを表す因果効果$E(\mathbf{y}_{i}) - E(\mathbf{y}_{0})$を、次の一般化線形モデルによって推定する。
$$
\mathbf{y}_{i} = \sum_{i = 1}^{I} (\boldsymbol{\gamma}_{i}\mathbf{z}_{i}) \mathbf{w}_{i},
\text{where}\ E(\mathbf{y}_{i}) = \boldsymbol{\gamma}_{i}, \ E(\mathbf{y}_{0}) = \boldsymbol{\gamma}_{I}
$$

推定後のデータ書き出し処理は、"93_fallback_glm.R"と同様である。

### 05-1_ui.R
Shiny Dashboardによって、因果効果の大小を比較し図化する。次のパーツによってShiny Dashboardを作成する。

* サービスの種類と概要を表示する。@ 05-1_ui_info.R
* 比較したいサービスを選択するタブパネル。3種類比較できるようにしている。@ 05-1_ui_tabPanel_at_comparison.R
* タブパネルと選択可能パターン表を表示する。@ 05-1_ui_comparison.R
* データ分割×グループ別因果効果※をグラフ化する。@ 05-1_ui_ranking.R
※縮退時はサービス導入効果$\boldsymbol{\gamma}_{i}$
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

### フローチャート
```flow
st=>start: ルーチン開始
e=>end: ルーチン終了
abend=>end:  |flow-terminal

io1=>inputoutput: 生データ
io2=>inputoutput: 1-1.整形済データ・
分割なし/あり
io3=>inputoutput: 2-1.GPS結合済データ
・分割なし/あり
io4=>inputoutput: 3-1.IPW結合済データ
・分割なし/あり
io5=>inputoutput: 4-1.逸脱残差結合
済データ・分割
なし/あり
io6=>inputoutput: 4-2.推定結果・
分割なし/あり
io7=>inputoutput: 2-2.縮退時GLM用データ
・分割なし/あり
io8=>inputoutput: R3-1.逸脱残差結合
済データ・分割
なし/あり
io9=>inputoutput: R3-2.推定結果・
分割なし/あり

cond1=>condition: 属性別分割済データ
出力4条件の満足
cond2=>condition: IPW計算用データ
出力4条件の満足
cond3=>condition: 縮退用一般化線形
モデル（GLM）用
データ出力3条件
の満足
cond4=>condition: 推定結果出力
cond5=>condition: 推定結果出力

sub1=>subroutine: 1.データ整形と整形済
データの属性別分割
sub2=>subroutine: 2.一般化傾向スコア
（GPS）の推定
sub3=>subroutine: 3.逆確率重み（IPW）
の計算
sub4=>subroutine: 4.GLMでIPW推定量
（IPWE）を計算
sub5=>subroutine: R3.縮退時GLMでサービス
導入効果を推定
sub6=>subroutine: 5.Shiny Dashboard
で可視化

st->io1->sub1->cond1->
cond1(yes)->io2->sub2->cond2->
cond1(no)->abend
cond2(yes)->io3->sub3->io4->sub4->cond4->
cond2(no)->cond3
cond3(yes)->io7->sub5->cond5->
cond3(no)->abend
cond4(yes)->io6->sub6->e
cond4(no)->io5(right)->
cond5(yes)->io9->sub6->e
cond5(no)->io8(right)->
​```