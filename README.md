# Teleport Anywhere

**Teleport Anywhere** は、Factorio 2.0向けのプレイヤー専用テレポートMODです。

マップ上で指定した地点へ瞬時に移動できます。

Space Ageを導入している場合は、さらに一度訪問した惑星への惑星間テレポートが利用できます。

このMODが移動させるのは**プレイヤーキャラクターのみ**です。
アイテムや車両、列車、物流貨物などを転送する機能はありません。

そのため、Factorio本来の物流を維持したまま、広大な工場や複数惑星を管理する際のプレイヤー自身の移動時間だけを短縮できます。

---

## 主な機能

### マップテレポート

現在いるSurface内の任意地点へテレポートできます。

1. 画面左上のTeleport Anywhereアイコンをクリック
2. `Map Teleport` を選択
3. Remote Viewで移動したい地点を範囲選択
4. 選択範囲の中央付近へテレポート

テレポート先に建築物、水、崖などがある場合は、Factorioのcollision判定を利用して周辺の安全な地点を自動的に検索します。

安全に配置できる地点が見つからなかった場合、テレポートは実行されません。

---

## Space Age対応

Space Ageは**任意依存**です。

### Factorio 2.0のみ

以下の機能を利用できます。

* 現在Surface内でのMap Teleport
* Remote Viewからの地点指定
* 安全地点の自動探索

### Factorio 2.0 + Space Age

上記に加えて、

* 訪問済み惑星へのテレポート
* MODによって追加された惑星への対応

が利用できます。

---

## 惑星間テレポート

Space Ageが有効な場合、Teleport AnywhereのGUIに訪問済み惑星が表示されます。

例：

```text
Teleport Anywhere

Current: Nauvis

[ Map Teleport ]

Planets

[ Nauvis - Current ]
[ Vulcanus ]
[ Fulgora ]
```

目的の惑星を選択すると、その惑星へ直接テレポートします。

### 訪問済み惑星のみ

まだ一度も訪れていない惑星にはテレポートできません。

VulcanusやFulgoraなどへ初めて向かう際は、通常通りSpace Platformを使用する必要があります。

一度実際に到達した惑星は、その後Teleport Anywhereから移動できるようになります。

そのため、このMODを利用してSpace Ageの初回惑星到達を省略することはできません。

---

## 惑星での到着地点

惑星間テレポートでは、以下の優先順位で到着地点を決定します。

1. **Cargo Landing Pad付近**
2. Cargo Landing Padが存在しない場合は、その惑星の**Spawn Position付近**

基準地点へ無条件に配置するのではなく、その周辺からプレイヤーキャラクターを安全に配置できる地点を検索します。

---

## MOD追加惑星

惑星名はハードコードしていません。

Space Age環境ではFactorioのPlanet情報から利用可能な惑星を取得するため、他のMODによって追加された惑星にも可能な限り自動対応します。

ただし、独自の特殊なSurfaceや通常のPlanetとして登録されていないSurfaceは対象外です。

---

## Space Platform

Space Platformへのテレポートには対応していません。

以下の移動はできません。

* Planet → Space Platform
* Space Platform → Planet
* Space Platform → Space Platform
* Space Platform内でのMap Teleport

Space Platformは通常のSpace Ageシステムを利用してください。

---

## 操作方法

### GUI

プレイ画面左上にTeleport Anywhereのアイコンが表示されます。

クリックするとTeleport GUIを開閉できます。

### キーボード

デフォルト：

```text
Alt + M
```

Teleport GUIを開閉します。

キー設定はFactorioの操作設定から変更できます。

---

## Map Teleportの地点指定について

Map TeleportではFactorio標準のSelection Toolを使用します。

`Map Teleport` を押したあと、目的地点を範囲選択してください。

**選択した範囲の中央**がテレポートの基準地点になります。

正確な1Tileを指定したい場合は、その地点を小さく選択してください。

---

## 安全地点探索

Teleport Anywhereは、水や建築物などを独自に個別判定するのではなく、Factorioのcollision判定を利用します。

指定地点にプレイヤーを配置できない場合は、その周辺から配置可能な地点を検索します。

安全地点が見つからなかった場合は、プレイヤーを不正な場所へ強制的に移動させることなく、テレポートを中止します。

---

## テレポート対象

テレポートするもの：

* プレイヤーキャラクター
* プレイヤーが通常所持しているインベントリ
* 装備中のArmorやEquipment

テレポートしないもの：

* 車両
* Spidertron
* 列車
* 建築物
* ロボット
* 物流貨物
* その他のユニット

車両に乗っている状態ではテレポートできません。

---

## マルチプレイヤー

マルチプレイヤーに対応しています。

GUIやMap Teleportの地点選択状態はプレイヤーごとに独立して管理されます。

Space Age環境での訪問済み惑星はForce単位で共有されます。

そのため、同じForceに所属するプレイヤーは、そのForceで訪問済みとして記録された惑星へテレポートできます。

---

## このMODの目的

Teleport Anywhereは、Factorioの物流をテレポートで置き換えるMODではありません。

目的は、

> **「プレイヤー自身の移動に掛かる待ち時間だけを省略すること」**

です。

資材を別の工場へ運ぶには列車やベルト、物流ロボットなどが必要です。

Space Ageで別惑星へ資材を運ぶ場合も、ロケット、Space Platform、Cargo Landing Padなど通常の惑星間物流が必要です。

一方、

「遠く離れた工場の様子を直接確認したい」

「Vulcanusの工場を少し修正したい」

「Fulgoraを確認したあとNauvisへ戻りたい」

といった、**プレイヤー自身が移動するためだけの時間をTeleport Anywhereで短縮できます。**

---

## 対応環境

* Factorio 2.0
* Space Age（任意）

Space AgeなしでもMap Teleportを利用できます。

---

## Version 1.0

実装機能：

* Map Teleport
* Selection Toolによる地点指定
* Remote View対応
* 安全地点探索
* GUI
* キーボードショートカット
* Space Age任意対応
* 訪問済み惑星へのテレポート
* Cargo Landing Pad付近への到着
* Spawn Positionへのフォールバック
* MOD追加惑星への動的対応
* マルチプレイヤー対応
* 英語・日本語対応

---

## License

ライセンスについてはリポジトリ内のLICENSEファイルを参照してください。
