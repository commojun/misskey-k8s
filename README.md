# k8s-misskey
misskeyをおうちkubernetesで構築する

https://qiita.com/nexryai/items/78e272d9bc36317d728a
こちらの記事のdocker-composeを参考にする

## 方針

それぞれのコンテナは以下のノードに割り当てられるようにする
- pi41: dbとredis
- pi31,32,33: web

## 事前準備

- nfsが準備できていて、各ノードがネットワークストレージにアクセスできること

memo

次はwebを書く。
