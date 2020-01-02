# R言語による技術の棚卸し #
成果物（2019/12/29時点）は以下のとおりです。各々の詳細は、該当のMarkdownを参照してください。

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