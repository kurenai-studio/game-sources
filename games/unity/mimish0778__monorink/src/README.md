# Mono Rink

1 台のキーボードで 2 人が対戦する、ローカル対戦用のエアホッケーゲームです。Unity で制作しました。

<img width="1451" height="807" alt="Mono Rink のプレイ画面" src="https://github.com/user-attachments/assets/aea4ab98-7e26-4a0e-824c-497c786486f5" />

**unityroom でプレイ:** https://unityroom.com/games/monorink

## ルール

- 左側が Player Red、右側が Player Blue です。パドルを上下に動かし、回転させてパックを打ち返します。
- パックを相手側のゴールに入れると 1 点です。先に 9 点を取ったプレイヤーの勝ちです。
- 得点はコートの両脇に並んだランプで表示されます。
- ゴールが決まるたびにパックは中央に戻り、少し間をおいて左右どちらかにランダムに動き出します。
- パックの速さには上限と下限があり、ラリー中に失速して止まることはありません。

### カーブショット

カーブショットのキーを押したまま、パドルを上か下に動かしている状態でパックに当てると、当たった 0.5 秒後にパックがその方向へ曲がります。

- 1 試合につき、各プレイヤー 3 回まで使えます。
- 残りの回数は、パドル上の 3 つのランプで表示されます。

## 操作方法

| 操作 | Player Red | Player Blue |
| --- | --- | --- |
| 上下に移動 | `W` / `S` | `↑` / `↓` |
| 時計回りに回転 | `D` | `→` |
| 反時計回りに回転 | `A` | `←` |
| カーブショット（押したまま） | `Space` | 右 `Shift` |

タイトル画面で「Press Start」が表示されたら、いずれかのキーを押すと試合が始まります。決着がついて 5 秒たつと、いずれかのキーでタイトル画面に戻ります。

## 開発環境

- Unity 2022.3.61f1
- TextMesh Pro 3.0.7
- 2D 物理（Rigidbody2D）

## プロジェクトを開く

1. リポジトリをクローンします。

   ```bash
   git clone https://github.com/mimish0778/monorink.git
   ```

2. Unity Hub で Unity 2022.3.61f1 をインストールし、クローンしたフォルダをプロジェクトとして開きます。
3. `Assets/Project/Scenes/Start.unity` を開いて再生します。

シーンは Start（タイトル）と Play（対戦）の 2 つで、この順にビルド設定に登録されています。

## プロジェクト構成

```
Assets/Project/
├── Audios/      打球音とゴール音
├── Fonts/       Caveat フォント
├── Materials/
├── Scenes/      Start / Play
└── Scripts/
    ├── FadeController.cs           シーン切り替え時のフェード
    ├── Start/
    │   ├── PuckWhiteController.cs  タイトル画面の演出と、対戦画面への遷移
    │   └── StartPromptController.cs 「Press Start」の点滅
    └── Play/
        ├── PlayerControllerBase.cs パドルの移動・回転と、カーブショットの残り回数
        ├── PlayerRedController.cs  Player Red のキー割り当て
        ├── PlayerBlueController.cs Player Blue のキー割り当て
        └── PuckBlackController.cs  パックの挙動、得点、勝敗判定
```

## ライセンス

ソースコードは [MIT License](LICENSE) で公開しています。

同梱のフォント [Caveat](https://fonts.google.com/specimen/Caveat) には SIL Open Font License 1.1 が適用されます。

効果音（`Assets/Project/Audios/`）はフリー素材を使用しており、このライセンスの対象外です。
