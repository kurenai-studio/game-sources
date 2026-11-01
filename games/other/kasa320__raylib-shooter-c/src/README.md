# 2D Search and Destroy

C言語と [raylib](https://www.raylib.com/) で制作した2Dタクティカルシューターです。  
*Counter-Strike* や *VALORANT* の爆破モード（Search and Destroy）をベースに、戦略的なゲーム性を2Dで再現しました。  
プレイヤー（攻撃側）は5体のAI（守備側）が守るマップに潜入し、**敵の全滅**または**爆弾の設置・爆破**を目指します。

![視野システムのデモ — 壁から出て敵を発見・射撃するシーン](resources/demo.gif)

## 実装のポイント

- **レイキャスティングによる動的視界システム**  
  プレイヤーの向く方向にリアルタイムで数百本のレイを飛ばし、壁との交点から視野ポリゴンを生成します。視野外の敵は描画されず、スモークグレネードも同じパイプラインで障害物として扱います。

- **BFSによる自律型AI**  
  爆弾設置時に設置場所を起点とした距離マップを幅優先探索で動的生成します。敵ボットはこのマップを参照して障害物を回避しながら最短経路で爆弾へ向かい、*GUARDING / APPROACHING / DEFUSING* の3状態を状況に応じて遷移します。

- **タクティカルな戦闘要素**  
  回数制限付きダッシュ、スモークグレネード、手動リロード、ヘッドショット判定、難易度に応じた敵の発射レートなど。

- **演出面の作り込み**  
  射撃時のカメラシェイク（減衰あり）、移動アニメーション、各アクションへのSE。射撃音は `SoundAlias` を使った交互再生で連続発砲時の途切れを解消しています。

## ビルド方法

**事前準備:** [raylib](https://www.raylib.com/) をインストールしてください。

```sh
make
./game
```

手動でコンパイルする場合（macOS）:
```sh
gcc -o game main.c utils.c scene_menu.c scene_1v5.c \
    -I/opt/homebrew/include -L/opt/homebrew/lib \
    -lraylib -framework IOKit -framework Cocoa -framework OpenGL
```

手動でコンパイルする場合（Linux）:
```sh
gcc -o game main.c utils.c scene_menu.c scene_1v5.c \
    -I/usr/local/include -L/usr/local/lib \
    -lraylib -lGL -lm -lpthread -ldl -lrt -lX11
```

> Intel Mac の場合はパスを `/opt/homebrew` → `/usr/local` に変更してください。

## 操作方法

| 操作 | キー / マウス |
|------|--------------|
| 移動 | W / A / S / D |
| エイム・射撃 | マウス移動 / 左クリック |
| ダッシュ | Left Shift（回数制限あり） |
| スモーク展開 | E で場所を選択し左クリックで確定 |
| リロード | R |
| 爆弾設置 | 白枠エリア内で F 長押し |

## 勝敗条件

| | 条件 |
|-|------|
| **勝利** | 敵を5人全員倒す、または爆弾を設置して爆破に成功する |
| **敗北** | 自分のHPが0になる、または設置した爆弾を解除される |

## ディレクトリ構成

```
.
├── main.c          # エントリポイント、ゲームループ、シーン管理
├── common.h        # 共通の型定義・定数・関数プロトタイプ
├── scene_menu.c    # メニュー画面
├── scene_1v5.c     # メインゲームシーン（描画・リソース管理）
├── utils.c         # コアロジック（視野・AI・BFS・弾・爆弾・スモーク）
├── Makefile        # クロスプラットフォームビルド（macOS / Linux / Windows）
└── resources/
    ├── map/        # PNGエンコードされたタイルマップ
    ├── texture/    # スプライト（自作）
    └── audio/      # 効果音（下記クレジット参照）
```

## 使用素材・ライセンス

- **言語 / ライブラリ:** C言語 / [raylib](https://www.raylib.com/)（MIT License）
- **テクスチャ:** 自作
- **効果音:**
  - [効果音ラボ](https://soundeffect-lab.info/)
  - [OtoLogic](https://otologic.jp/)
  - [音人](https://on-jin.com/)
  - [魔王魂](https://maou.audio/category/se/se-battle/)
  - [効果音工房](https://umipla.com/)
  - [pixabay](https://pixabay.com/ja/)
