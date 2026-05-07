# k8s-misskey
misskeyをおうちkubernetesで構築する

こちらの記事のdocker-composeを参考にする: https://qiita.com/nexryai/items/78e272d9bc36317d728a

経緯はこちら: https://qiita.com/commojun/items/b9cb1ac7fb1b6c80d70a

## 方針

すべてのコンテナ(db, redis, web)を pi41 (4GB) に集約する。
当初は pi31/32/33 にwebを分散配置する想定だったが、Raspberry Pi 3B(メモリ1GB)ではmisskeyのwebコンテナが安定して動かなかったため、運用上pi41に寄せる構成に切り替えた。

## 事前準備

- [k0s-cluster](https://github.com/commojun/k0s-cluster)のようにしてk8sのクラスタが準備できていること
- nfsが準備できていて、各ノードがネットワークストレージにアクセスできること

## 構築方法

`envfile.sample` をコピーして `envfile` を用意し、必要な環境変数を設定する

nfsにmisskeyディレクトリを用意する
```
pi41 $ cd /home/commojun/nfs
pi41 $ mkdir misskey
pi41 $ cd misskey
pi41 $ mkdir redis
pi41 $ mkdir db
pi41 $ mkdir files
pi41 $ mkdir config
```

filesはコンテナ内の別ユーザが書き込みをするので権限を変更しておく
```
pi41 $ chmod 0777 files
```

設定をアップロードする
```
$ make config
```

namespaceを登録する
```
$ kubectl apply -f namespace.yml
```

secretを登録する
```
$ make secret
```

dbとredisのデプロイ
```
$ kubectl apply -f redis.yml
$ kubectl apply -f db.yml
```

port-forwardしてそれぞれが立ち上がっているか確認
```
$ kubectl port-forward redis 6379:6379
# 別のコンソール
$ redis-client -h localhost
```

```
$ kubectl port-forward db 5432:5432
# 別のコンソール
$ psql -h localhost -U misskey
```

webのデプロイ
```
$ kubectl apply -f web.yml
```

podの様子を確認
```
$ make pods
```

問題なく動作していた場合、 http://クラスタのいずれかのノードのIP:30080/ にアクセスすれば接続できる

## バージョンアップ

`web.yml` の `image: misskey/misskey:<タグ>` を新しいバージョンに書き換えて apply するだけで良い。
imageのデフォルトCMDが `pnpm run migrateandstart` なので、起動時に必要なマイグレーションが自動で走る。

```
$ kubectl apply -f web.yml
$ make pods
```

メジャーアップ等で複数バージョンを跨ぐ場合は、Misskey推奨に従って一段ずつ上げるのが安全。
