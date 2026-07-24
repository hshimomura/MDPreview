# MDPreview MVP 設計

## 結論

macOS 26専用の読み取り専用Markdownビューアとして、SwiftUIの
`DocumentGroup(viewing:)`とTextual 0.5.0を組み合わせる。WebKit、
Electron、独自エディタ、データベースは使わない。

この構成は、Finderから文書を開くmacOS標準の動作、複数ウインドウ、
ダークモード、アクセシビリティ、テキスト選択を小さなコード量で得られる。

## 構成

```text
Launch Services
  .md / .markdown
  UTI: net.daringfireball.markdown
          |
          v
SwiftUI DocumentGroup(viewing:)
  読み取り専用・複数ウインドウ・Openメニュー
          |
          v
MarkdownDocument
  UTF-8 Data -> immutable String
          |
          v
Textual StructuredText
  SwiftUIネイティブのMarkdownレンダリング
          |
          v
ScrollView + Read Onlyステータス
```

## OSS選定

| 候補 | 評価 | 判断 |
| --- | --- | --- |
| Textual 0.5.0 | SwiftUIネイティブ、2026年6月更新、MIT、表・コード・選択対応 | 採用 |
| MarkdownUI 2.x | 成熟しているがmaintenance mode | 新規採用は見送り |
| swift-markdown | Apache-2.0、GFM準拠のAST。ただし表示層を自作する必要がある | 将来の独自レンダラ候補 |
| Ink 0.6.0 | 軽量なHTML変換、MIT。ただし最終リリースが2023年 | 見送り |
| WebKit + HTML/CSS | 表現力は高いが、HTMLのサニタイズ、CSS、ローカル資源権限が増える | MVPでは不要 |
| Electron | クロスプラットフォーム化が不要で、配布サイズと更新面が過剰 | 不採用 |

## ライセンス方針

- アプリ本体はMITとする。
- SwiftPM依存はバージョンを固定し、`Package.resolved`を公開する。
- Textual、SwiftUIMath、ConcurrencyExtras、Prism.jsのライセンス全文を
  アプリ内に同梱する。
- SwiftUIMathのフォントライセンス（SIL OFL 1.1、GUST）は、
  元のリソースバンドル内のライセンスファイルをそのまま保持する。
- リリースごとに依存グラフと配布バンドルを再監査する。

MITはFSF/OSIの自由ソフトウェア・オープンソース条件を満たし、
無料配布にも有償再配布にも使える。改変版にも同じ自由を強制したい場合は、
アプリ本体だけGPLv3へ変更できる。採用依存はいずれもGPLv3との組み合わせが
可能な許諾形態だが、変更時には改めて法務確認する。

## MVP受け入れ条件

- Xcode 26でreleaseビルドできる。
- 生成物が有効な`.app`バンドルで、ad-hoc署名を検証できる。
- `.md`と`.markdown`をViewerロールで登録する。
- FinderまたはOpenメニューからUTF-8 Markdownを開ける。
- Markdownが編集UIなしでレンダリングされる。
- テスト、Info.plist、署名、依存ライセンス同梱を検証できる。

## 次の段階

### 0.2

- 外部変更の監視と自動再読み込み
- 相対パス画像の安全な読み込み
- Find、アウトライン、文字サイズ変更
- 印刷とPDF書き出し

### 0.3

- Apple silicon / IntelのUniversal 2ビルド
- アプリアイコン、About画面、ライセンス画面
- Developer ID署名、Hardened Runtime、notarization、staple
- GitHub Actionsでテストし、タグ付きリリースは保護された署名環境で生成

### 1.0

- 大規模文書の性能試験
- VoiceOver、キーボード操作、コントラストの監査
- クラッシュレポートを送信しない、完全ローカル動作の明文化
- SBOMとSHA-256チェックサムをGitHub Releaseへ添付
