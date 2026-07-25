# MDPreview MVP 設計

## 結論

macOS 26専用の読み取り専用Markdownビューアとして、SwiftUIの
`DocumentGroup(viewing:)`とTextual 0.5.0を組み合わせる。Mermaidだけは
同梱ランタイムを隔離したローカルWebKitで描画する。Electron、独自エディタ、
データベース、Quick Look拡張は使わない。

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
PreviewDocumentModel
  ファイル実体を監視し、外部保存時に再読み込み
          |
          v
MarkdownContentParser
  見出し / 通常Markdown / Mermaidを分離
          |
          +--> Textual StructuredText
          |    SwiftUIネイティブのMarkdownレンダリング
          |
          +--> WKWebView + 同梱Mermaid
               strict security・外部遷移禁止・オフライン
```

## OSS選定

| 候補 | 評価 | 判断 |
| --- | --- | --- |
| Textual 0.5.0 | SwiftUIネイティブ、2026年6月更新、MIT、表・コード・選択対応 | 採用 |
| Mermaid 11.15.0 | 図表記法の事実上の標準、MIT、固定版をオフライン同梱可能 | Mermaidブロックだけに採用 |
| MarkdownUI 2.x | 成熟しているがmaintenance mode | 新規採用は見送り |
| swift-markdown | Apache-2.0、GFM準拠のAST。ただし表示層を自作する必要がある | 将来の独自レンダラ候補 |
| Ink 0.6.0 | 軽量なHTML変換、MIT。ただし最終リリースが2023年 | 見送り |
| WebKit + HTML/CSS | 文書全体には権限と攻撃面が過剰 | Mermaidだけに限定 |
| Electron | クロスプラットフォーム化が不要で、配布サイズと更新面が過剰 | 不採用 |

## ライセンス方針

- アプリ本体はMITとする。
- SwiftPM依存はバージョンを固定し、`Package.resolved`を公開する。
- Textual、SwiftUIMath、ConcurrencyExtras、Prism.js、Mermaidのライセンス全文を
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
- 外部エディタによる通常保存とatomic replaceを約0.4秒単位で検知する。
- 左の章立てが見出しへ移動でき、読書位置に追従して現在章を強調する。
- ContentsはツールバーまたはViewメニューから表示・非表示を切り替えられる。
- `mermaid` fenced code blockが追加セットアップやネットワークなしで描画される。
- FileメニューまたはCommand-PからmacOS標準のプリントパネルを開ける。
- テスト、Info.plist、署名、依存ライセンス同梱を検証できる。

## 次の段階

### 0.2

- 外部変更の監視と自動再読み込み（実装済み）
- 章立てと現在章追従（実装済み）
- Contents表示切替と印刷（実装済み）
- Mermaidのオフライン描画（実装済み）
- 印刷専用TextKitレイアウトによる印刷プレビュー（実装済み）。
  Mermaidは印刷時にソースコードへフォールバックする
- 相対パス画像の安全な読み込み
- Find、文字サイズ変更
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
