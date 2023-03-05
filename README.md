# k8s-misskey
misskeyをおうちkubernetesで構築する

こちらの記事のdocker-composeを参考にする: https://qiita.com/nexryai/items/78e272d9bc36317d728a

## 方針

それぞれのコンテナは以下のノードに割り当てられるようにする
- pi41: dbとredis
- pi31,32,33: web

raspberry pi3 はメモリが1GBしかないので割当を工夫する

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
