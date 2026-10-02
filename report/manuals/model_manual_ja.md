# 二次元 ALE-ANCF 可変長柔軟ロープ・タワークレーンモデル説明書

**日本語版 · バージョン 1.1 · 2026-09-28**  
対象プロジェクト：TowerCrane-OptimalControl  
対象コードの基準コミット：`6cab2e5`  
[中文版](model_manual_zh.md)

## 1. 目的とモデルの位置付け

本モデルは、二次元平面内におけるトロリの運動、支持点の鉛直振動、柔軟ロープの長さ変化、および吊り荷の振れの連成を解析するためのものです。動力学研究、パラメータ解析、今後の制御器設計に向けたシミュレーション基盤として使用できます。現時点では、トロリ駆動力とロープの巻上げ・繰出し軌道をあらかじめ与える開ループモデルであり、振れ止め制御や最適制御は実装していません。

ALE は任意ラグランジュ・オイラー記述、ANCF は絶対節点座標法を意味します。ANCF では節点位置と位置勾配により柔軟ロープの形状を表します。ALE では計算節点がロープ材料に対して移動できるため、材料が上端から計算領域へ流入・流出する現象を扱えます。

本実装は Li ら（2022）の ALE-ANCF 吊りロープモデルを参考とし、**二次元、指定された材料座標、固定要素数の移動メッシュ**を採用しています。塔体とジブは鉛直方向の単一ばね・ダンパ支持で近似しており、論文の有限要素モデル全体を再現したものではありません。

### 実装済みの内容と未実装の内容

| 実装済み | 未実装 |
|---|---|
| ロープの分布質量、軸方向伸び、曲げ弾性 | 三次元旋回と面外振れ |
| 幾何学的非線形性と平面内の大角度振れ | 塔体・ジブ全体のはり有限要素と移動滑りジョイント |
| 指定された巻上げ・繰出し運動と付加 ALE 慣性 | 巻上げモータ、ドラム、シーブ接触 |
| 支持点の鉛直弾性と支持部減衰 | ロープ内部減衰、弛緩後の運動、再緊張時の衝撃 |
| トロリの水平駆動力と重力 | 閉ループ振れ止め、最適制御、要素の自動分割・統合 |

例題のパラメータは説明用の有効値であり、実機や論文のパラメータに基づいて同定した値ではありません。大角度運動を扱えることは、任意の大ひずみを許容することを意味しません。軸方向の構成則は線形弾性です。

## 2. システム構成、座標および自由度

システムは、上端のトロリ・支持点の集中質量 `mT`、鉛直支持部 `kB,cB`、柔軟ロープ、および下端の吊り荷質点 `mP` から構成されます。支持ばねは上端の鉛直方向にのみ作用します。水平位置は運動方程式から求め、水平位置のサーボ拘束は与えていません。

水平方向は右向きを `x` の正、鉛直方向は下向きを `y` の正とします。支持点の鉛直変位 `d` は無負荷時の支持位置を基準とし、重力による静たわみを含みます。正の振れ角は、吊り荷が支持点の右側にあることを表します。

要素数を `n_e`、節点数を `n_e+1` とします。節点番号は `i=0,...,n_e` で、各節点の力学座標は次のとおりです。

$$
\begin{gathered}
\mathbf{q}_i=\left[x_i,\ y_i,\ x_{s,i},\ y_{s,i}\right]^{\mathsf{T}} \\
\mathbf{q}=\left[\mathbf{q}_0^{\mathsf{T}},\ \mathbf{q}_1^{\mathsf{T}},\ \ldots,\ \mathbf{q}_{n_e}^{\mathsf{T}}\right]^{\mathsf{T}} \\
\mathbf{z}=\left[\mathbf{q}^{\mathsf{T}},\ \dot{\mathbf{q}}^{\mathsf{T}}\right]^{\mathsf{T}}
\end{gathered}
$$

`x_s,y_s` は、未伸長の材料座標 `s` に関する位置の微分で、次元は m/m です。その大きさに伸びの情報が含まれるため、**単位接線ベクトルに正規化してはいけません**。`qdot` の勾配成分は位置勾配の時間微分であり、節点の角速度ではありません。

隣接要素は位置と勾配を共有し、中心線の C1 連続性を確保します。上端位置はトロリ・支持点と、下端位置は吊り荷と座標を共有します。両端の勾配は自由であり、方向固定の拘束や外部端モーメントは与えません。

力学座標数は `4(n_e+1)`、一階状態数は `8(n_e+1)` です。既定値の 3 要素・4 節点では、力学座標は 16、一階状態は 32 です。材料座標は入力として指定するため、これらの未知量には含めません。

## 3. 3 種類の長さと移動材料メッシュ

以下の長さを区別する必要があります。

| 量 | 意味 | 決定方法 |
|---|---|---|
| `L(t)` | 計算領域内の未伸長材料長 | 巻上げ入力として指定 |
| `arcLength(t)` | 変形後のロープ中心線の実弧長 | 変形した中心線を積分 |
| 支持点と吊り荷の距離 | 両端位置間の直線距離 | 端点座標から計算 |

ロープが曲がると弧長と両端間の直線距離は異なります。また、軸方向伸びが生じると実弧長と材料長は異なります。現在のメッシュは次式で与えます。

$$
\begin{gathered}
s_i(t)=\left(-1+\frac{i}{n_e}\right)L(t),\qquad i=0,\ldots,n_e \\
s_0(t)=-L(t),\qquad s_{n_e}(t)=0,\qquad \ell_e(t)=\frac{L(t)}{n_e}
\end{gathered}
$$

吊り荷は常に材料端点 `s=0` に接続します。巻上げ時は `Ldot<0` となり、上端の材料座標が増加して材料が上端から計算領域の外へ出ます。繰出し時は逆です。内部の計算節点は、一般に同一の材料点を追跡していません。

すべての要素長を比例的に変化させ、要素数は自動変更しません。計算領域内のロープ質量は `rhoA*L(t)` であり、巻上げ・繰出しにより変化します。ドラムに巻かれたロープとドラム本体は計算領域に含めません。

## 4. 動力学の原理

### 4.1 Hermite 補間

記号の混同を避けるため、本説明書では形状関数行列を `S` と表記します。コード内の名称は `N` です。要素両端の材料座標を `s_1,s_2` とし、`l=s_2-s_1`、`xi=(s-s_1)/l` とおくと、次式を得ます。

$$
\begin{gathered}
H_1=1-3\xi^2+2\xi^3,\qquad H_2=\xi-2\xi^2+\xi^3 \\
H_3=3\xi^2-2\xi^3,\qquad H_4=-\xi^2+\xi^3 \\
\mathbf{S}=\left[H_1\mathbf{I}_2,\ \ell H_2\mathbf{I}_2,\ H_3\mathbf{I}_2,\ \ell H_4\mathbf{I}_2\right] \\
\mathbf{q}_e=\left[\mathbf{r}_1^{\mathsf{T}},\ \mathbf{r}_{s,1}^{\mathsf{T}},\ \mathbf{r}_2^{\mathsf{T}},\ \mathbf{r}_{s,2}^{\mathsf{T}}\right]^{\mathsf{T}} \\
\mathbf{r}(s,t)=\mathbf{S}\mathbf{q}_e,\qquad \mathbf{B}=\frac{\partial\mathbf{S}}{\partial s},\qquad \mathbf{C}=\frac{\partial^2\mathbf{S}}{\partial s^2}
\end{gathered}
$$

### 4.2 材料速度と付加慣性

材料の運動を微分するときは、材料座標 `s` を固定する必要があります。

$$
\begin{gathered}
\dot{\xi}=-\frac{\dot{s}_1+\xi\dot{\ell}}{\ell} \\
\ddot{\xi}=-\frac{\ddot{s}_1+\xi\ddot{\ell}+2\dot{\xi}\dot{\ell}}{\ell} \\
\mathbf{v}_{\mathrm{mat}}=\mathbf{S}\dot{\mathbf{q}}_e+\mathbf{S}_t\mathbf{q}_e \\
\mathbf{a}_{\mathrm{mat}}=\mathbf{S}\ddot{\mathbf{q}}_e+2\mathbf{S}_t\dot{\mathbf{q}}_e+\mathbf{S}_{tt}\mathbf{q}_e
\end{gathered}
$$

したがって、移動メッシュの節点速度と、その位置を通過する材料の速度は通常一致しません。コードでは時間微分を解析的に計算し、次の項を構成します。

$$
\begin{gathered}
\mathbf{M}_e=\int_{s_1}^{s_2}\rho A\,\mathbf{S}^{\mathsf{T}}\mathbf{S}\,\mathrm{d}s \\
\mathbf{Q}_{\mathrm{ALE},e}=\int_{s_1}^{s_2}\rho A\,\mathbf{S}^{\mathsf{T}}\left(2\mathbf{S}_t\dot{\mathbf{q}}_e+\mathbf{S}_{tt}\mathbf{q}_e\right)\mathrm{d}s
\end{gathered}
$$

各材料節点の速度・加速度がゼロならば `S_t=S_tt=0` となり、固定材料メッシュの ANCF に帰着します。

### 4.3 軸方向および曲げの弾性

$$
\begin{gathered}
\mathbf{a}=\mathbf{B}\mathbf{q}_e,\qquad \mathbf{b}=\mathbf{C}\mathbf{q}_e,\qquad \varepsilon=\Vert\mathbf{a}\Vert-1 \\
\kappa=\frac{a_xb_y-a_yb_x}{\mathbf{a}^{\mathsf{T}}\mathbf{a}} \\
U_e=\frac{1}{2}\int_{s_1}^{s_2}\left(EA\,\varepsilon^2+EI\,\kappa^2\right)\mathrm{d}s \\
\mathbf{Q}_{\mathrm{el},e}=\frac{\partial U_e}{\partial\mathbf{q}_e}
\end{gathered}
$$

`kappa` は参考論文で採用された曲率尺度であり、分母を `norm(a)^3` とする幾何学的曲率ではありません。ここでは符号付きの形を使いますが、その二乗は絶対値を使う場合と同じ曲げエネルギーを与えます。弾性力はエネルギーの解析的勾配から求め、各要素に 8 点 Gauss 積分を用います。

### 4.4 全体系の方程式と数値解法

$$
\begin{gathered}
\mathbf{M}(t)\ddot{\mathbf{q}}=\mathbf{F}_{\mathrm{g}}+\mathbf{F}_{\mathrm{T}}+\mathbf{F}_{\mathrm{B}}-\mathbf{Q}_{\mathrm{el}}-\mathbf{Q}_{\mathrm{ALE}} \\
F_{\mathrm{B},y}=-k_Bd-c_B\dot{d}
\end{gathered}
$$

式中の上付きの点と二重点は、それぞれ一階および二階の時間微分を表します。太字はベクトルまたは行列です。F_g、F_T、F_B は重力、トロリ駆動力、支持力を表し、添字 el は弾性項を表します。両端の質量はシステム質量行列に加え、両端質量およびロープの重力を重力項に含めます。

座標共有により接続拘束を消去した後、非特異な時変質量行列 `diag(I,M(t))` を用いて `ode15s` で積分し、疎な Jacobian のパターンを指定します。ラグランジュ乗数を含む完全な拘束 DAE を直接解く方式ではありません。幾何積分はキャッシュして再利用できますが、弾性力は現在の状態に応じて毎回計算します。

## 5. 既定パラメータと入力軌道

パラメータの入口は `aleancf.parameters` です。最初に `flexcrane.parameters` を読み込み、ロープ減衰パラメータ `cR` を削除した後、ALE-ANCF 用の値を上書きします。したがって、`aleancf.parameters()` の返す値を使用してください。

| フィールド | 既定値 | 単位・意味 |
|---|---:|---|
| `mT` | 20 | kg、上端集中質量 |
| `mP` | 5 | kg、吊り荷質量 |
| `g` | 9.81 | m/s²、重力加速度 |
| `kB` | 6000 | N/m、鉛直支持剛性 |
| `cB` | 30 | N·s/m、鉛直支持減衰 |
| `EA` | 20000 | N、ロープの軸剛性パラメータ |
| `EI` | 0.02 | N·m²、ロープの有効曲げ剛性 |
| `rhoA` | 0.10 | kg/m、未伸長単位長さ当たりの質量 |
| `nElem` | 3 | 要素数 |
| `L0` / `L1` | 2 / 1.4 | m、初期・最終材料長 |
| `hoistStart` | 2 | s、巻上げ・繰出しの開始時刻 |
| `hoistDuration` | 6 | s、巻上げ・繰出しの所要時間 |
| `forceAmplitude` | 4 | N、水平力振幅 |
| `forceDuration` | 4 | s、水平力の作用時間 |
| `theta0` | `3*pi/180` | rad、初期傾斜角、すなわち 3° |
| `tEnd` | 12 | s、解析終了時刻 |
| `relTol` / `absTol` | `2e-7` / `1e-9` | 相対・絶対誤差許容値 |
| `maxStep` | 0.02 | s、内部積分刻みの上限 |
| `nOutput` | 601 | 等間隔の保存点数 |

`EA` と `EI` は独立な有効パラメータです。現モデルでは、ワイヤロープの断面構造や材料同定との対応を与えていません。

入力関数は `flexcrane.inputs` にあり、従来の低次元モデルとも共用します。`tau=clip((t-hoistStart)/hoistDuration,0,1)` とすると、入力は次式です。

$$
\begin{gathered}
\tau=\operatorname{clip}\!\left(\frac{t-t_h}{T_h},\,0,\,1\right) \\
L(t)=L_0+(L_1-L_0)\left(10\tau^3-15\tau^4+6\tau^5\right) \\
u(t)=F_0\sin^3\!\left(\frac{2\pi t}{T_f}\right),\qquad 0\leq t\leq T_f
\end{gathered}
$$

式中の `t_h`、`T_h`、`F_0`、`T_f` は、それぞれコードの `hoistStart`、`hoistDuration`、`forceAmplitude`、`forceDuration` に対応します。τ は正規化時間、clip は指定区間への制限を表します。

水平力の式は `0<=t<=forceDuration` の区間のみで有効で、それ以外はゼロです。既定例では 0–4 s に正負の滑らかな力パルスを与え、2–8 s に材料長を 2 m から 1.4 m へ短縮します。コードは整合した `Ldot,Lddot` も計算します。長さ軌道を変更するときは、その時間微分も同時に変更してください。

### 初期状態

鉛直静的釣合い場にはロープ自重を含めます。`eta=s+L0` を上端から測った材料距離とします。

$$
\begin{gathered}
d_0=\frac{(m_T+m_P+\rho A L_0)g}{k_B} \\
y(\eta)-d_0=\eta+\frac{m_Pg\eta+\rho A g\left(L_0\eta-\frac{\eta^2}{2}\right)}{EA} \\
y_s=1+\frac{m_Pg+\rho A g(L_0-\eta)}{EA}
\end{gathered}
$$

この形状を上端の周りに `theta0` だけ回転し、初期一般化速度をゼロとします。`theta0=0`、水平入力なし、巻上げ・繰出しなしの場合が静的釣合いの試験条件です。既定の 3° 傾斜状態からの解放は静的釣合いではありません。入力を変更する場合は、初期長を `L0`、初期巻上げ・繰出し速度をゼロに保つか、整合した初期状態を改めて導出してください。

## 6. 準備と実行方法

MATLAB R2026a で動作を検証しています。描画インターフェースは MATLAB R2020a 以降を想定しています。基本 MATLAB のみを使用し、追加のツールボックスは不要です。以下のコマンドはプロジェクトのルートフォルダで実行します。

### 6.1 再計算せずに保存済み結果を見る

```matlab
addpath('matlab');
load('report/aleancf/simulation.mat','out');
aleancf.plot_results(out);
```

### 6.2 既定条件で計算する

```matlab
addpath('matlab');
out = tower_crane_aleancf;
```

既定では図を表示し、`report/aleancf/` に結果を書き込みます。再実行すると、同じフォルダの `simulation.mat`、`simulation.csv`、`simulation.png` を上書きします。

```matlab
out = tower_crane_aleancf(false,false); % 描画も保存もしない
out = tower_crane_aleancf(true,false);  % 描画するが保存しない
out = tower_crane_aleancf(false,true);  % MAT/CSV を保存し、新しい図は作らない
```

最後の方法では既存の PNG を更新しないため、画像が以前の計算条件に対応している場合があります。

### 6.3 パラメータを変更して別名で保存する

```matlab
p = aleancf.parameters();
p.nElem = 6;
p.L1 = 1.6;
out = aleancf.simulate(p);
fig = aleancf.plot_results(out);

folder = fullfile('report','aleancf_case_L16');
if ~exist(folder,'dir'), mkdir(folder); end
save(fullfile(folder,'simulation.mat'),'out');
exportgraphics(fig,fullfile(folder,'simulation.png'),'Resolution',150);
```

`aleancf.simulate(p)` は結果を返すだけで、自動保存しません。主関数 `tower_crane_aleancf` の 2 引数は描画と保存の切替え用であり、パラメータ構造体を受け取りません。独自のパラメータには上記の方法を用いてください。

### 6.4 検証をすべて実行する

```matlab
test_aleancf;
```

複数の 12 s 解析と 3、6、9 要素の比較を含むため、実行には時間がかかる場合があります。要素数や剛性を増やすと高周波振動と計算負荷が増加します。`nOutput` は保存時刻を指定するだけであり、誤差許容値や `maxStep` による積分精度の管理を代替しません。

## 7. 出力データと図の読み方

| `out` フィールド | 意味 |
|---|---|
| `t` | 保存時刻、単位 s |
| `q` / `v` | 各時刻の力学座標・一般化速度。1 行が 1 時刻に対応 |
| `z` | `[q,v]` を結合した状態行列 |
| `p` | 計算に使用したパラメータ |
| `theta` | 支持点から吊り荷への弦線が鉛直下向きとなす角、単位 rad |
| `L` / `arcLength` | 材料長・中心線実弧長、単位 m |
| `axialForceMin` | 各保存時刻における全 Gauss 点の `EA*strain` の最小値、単位 N |
| `aleForceNorm` | 付加 ALE 一般化力ベクトルのユークリッドノルム。診断用 |
| `energy` | ロープと両端質量の運動エネルギー、重力位置エネルギー、ロープひずみエネルギー、支持ばねエネルギーの和、単位 J |

`v` は力学座標の時間微分であり、各点の材料速度ではありません。材料速度は第 4 節の式で計算します。`aleForceNorm` は位置および勾配に対応する一般化成分を混在させた量なので、単一の点に作用する力や、単純に N 単位を持つ量として解釈しないでください。

節点 `i=0,...,n_e` の位置は `q` の列 `4*i+1,4*i+2`、勾配は列 `4*i+3,4*i+4` に格納されます。例：

```matlab
nq = size(out.q,2);
xT = out.q(:,1);       d = out.q(:,2);
xP = out.q(:,nq-3);    yP = out.q(:,nq-2);
swingDeg = out.theta*180/pi;
```

CSV は端点位置、弦線角、2 種類の長さ、最小軸力、ALE ノルムなどの要約を保存します。全節点の状態は MAT ファイルの `out` に格納されます。CSV の角度は rad、図の角度は deg です。

6 枚の図は順に、水平位置、弦線振れ角、材料長と実弧長、標本上の最小軸力、支持点鉛直変位、および複数時刻のロープ形状を示します。ロープ形状図の鉛直軸は下向きで、両端を丸印で示し、横・縦方向に同じ長さ尺度を用います。

既定の保存間隔は 0.02 s、すなわち 50 Hz のサンプリングです。高周波のロープ振動や軸力は十分に標本化されない可能性があります。周波数解析やピーク値評価では `nOutput` を増やし、サンプリングに関する収束も確認してください。柔軟ロープには全体で共通の局所振れ角はなく、弦線角は局所接線角や曲率の代わりにはなりません。

![保存済みの既定条件による解析結果](../aleancf/simulation.png)

## 8. 検証記録とその解釈

以下の値は、保存済みの `report/aleancf/validation.txt` から引用した過去の MATLAB 検証結果です。本説明書の作成時に再計算した値ではありません。

| 検証項目 | 記録された値 |
|---|---:|
| 固定長・無入力・無減衰時のエネルギードリフト | `1.107e-11 J` |
| 時間積分許容値を厳しくした場合の最大弦線角差 | `1.412e-11 rad` |
| 3 要素と 6 要素の最大弦線角差 | `1.376e-07 rad` |
| 6 要素と 9 要素の最大弦線角差 | `2.367e-08 rad` |
| 既定例の最大絶対弦線角 | `4.131286 deg` |
| 既定例の標本上の最小軸方向構成力 | `48.410404 N` |

さらに、固定材料点の速度・加速度、移動メッシュ上の静止材料場、固定長 ANCF 極限、ひずみエネルギー勾配、質量行列、および自重下の静的釣合いを確認しています。記録上の Code Analyzer の指摘は、疎行列の添字処理に関する性能上の助言が 2 件です。

これらの検証は、実装内部の数値的整合性と、本例における弦線振れ角のメッシュ収束傾向を支持します。実機による妥当性確認ではなく、すべての高周波力や曲率の収束、あるいは参考論文の再現を保証するものでもありません。

**可変長の場合は開いた材料領域です。** `energy` が一定になることを要求できず、トロリの仕事だけでエネルギー変化を説明することもできません。現在、巻上げ動力と境界エネルギー流束の完全な収支評価は未実装です。固定長のエネルギー検証は、その代わりにはなりません。

## 9. 適用条件とよくある問題

| 現象・エラー | 意味と対処 |
|---|---|
| `aleancf` または主関数が見つからない | プロジェクトのルートフォルダに移動し、`addpath('matlab')` を実行する |
| `aleancf:Compression` | いずれかの Gauss 点で軸ひずみがゼロまで低下し、現在の張力状態モデルの範囲を外れた。入力軌道、初期状態、パラメータを確認する |
| `aleancf:Collapsed` | 中心線の材料接線ベクトルが極端に小さくなり、要素が退化した。形状、パラメータ、運動範囲を確認する |
| 計算が遅い | 高剛性、細かいメッシュ、厳しい誤差許容値が計算量を増やす。まず既定の 3 要素または保存済み MAT を利用する |
| ロープ形状がほぼ直線に見える | 張力が大きい場合には正常。曲げを扱っているかどうかは要素方程式と `EI` で判断する |
| 長さ変更中にエネルギーが変化する | 開いた領域のエネルギー流れと数値誤差を区別し、直ちに保存則違反と判断しない |
| 独自条件で計算してもファイルができない | `simulate(p)` は保存しないため、`save` や画像出力を明示的に行う |

入口では、長さ、質量、`EA,EI,rhoA,kB` などの正値と、`nElem` が正整数であることを確認します。支持減衰は物理的には非負としてください。イベント検出は積分点における軸ひずみの正からゼロへの低下を監視するもので、完全な弛緩モデルでも、すべての場所・時刻での張力の保証でもありません。

入力関数は新旧モデルで共用しているため、変更は両方に影響します。`cR` は ALE-ANCF パラメータから削除されており、旧モデルの `cR` を変更しても本モデルにロープ内部減衰は追加されません。

## 10. ファイル一覧と参考資料

以下のパスはプロジェクトのルートフォルダを基準とします。

| ファイル | 役割 |
|---|---|
| `matlab/tower_crane_aleancf.m` | 既定解析、保存、描画の入口 |
| `matlab/+aleancf/parameters.m` | ALE-ANCF のパラメータと上書き値 |
| `matlab/+flexcrane/parameters.m`、`inputs.m` | 継承パラメータと共通入力軌道 |
| `matlab/+aleancf/initial_state.m` | 初期釣合い形状と傾斜状態からの解放 |
| `matlab/+aleancf/shape.m`、`geometry.m` | 補間、ALE 微分、幾何積分キャッシュ |
| `matlab/+aleancf/element.m` | 要素質量、弾性、重力、ALE 慣性 |
| `matlab/+aleancf/assemble.m`、`mass.m` | 全体組立てと一階系の質量行列 |
| `matlab/+aleancf/simulate.m`、`rhs.m` | 解析用積分・イベント検出、および陽的加速度形式の補助インターフェース |
| `matlab/+aleancf/plot_results.m` | 結果構造体からの描画 |
| `matlab/test_aleancf.m` | 物理的整合性と収束の試験 |
| `report/aleancf/` | 保存済みの解析結果と検証記録 |

参考文献：Kun Li, Manlan Liu, Zuqing Yu, Peng Lan, Nianli Lu (2022), “Multibody system dynamic analysis and payload swing control of tower crane”, *Proceedings of the Institution of Mechanical Engineers, Part K: Journal of Multi-body Dynamics*, 236(3), 407–421. [DOI: 10.1177/14644193221101994](https://doi.org/10.1177/14644193221101994)。

本説明書における現実装の記述は、コードと保存済み検証記録を直接の根拠としています。論文は手法の出典です。今後は要素の自動分割・統合、ジブ全体の柔軟モデル、アクチュエータ、振れ止め制御などへ拡張できますが、それぞれ独立した検証が必要です。
