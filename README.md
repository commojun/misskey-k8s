# k8s-misskey
misskeyをおうちkubernetesで構築する

https://qiita.com/nexryai/items/78e272d9bc36317d728a
参考にするdocker-compose.yml
```
version: "3"

services:
  web:
    image: misskey/misskey:latest
    restart: always
    links:
      - db
      - redis
    ports:
      - "3000:3000"
    networks:
      - misskey_db
      - external_network
    volumes:
      - ./files:/misskey/files
      - ./misskey.yaml:/misskey/.config/default.yml:ro

  redis:
    restart: always
    image: redis:4.0-alpine
    networks:
      - misskey_db
    volumes:
      - ./var/redis:/data

  db:
    restart: always
    image: postgres:latest
    networks:
      - misskey_db
    environment:
      - POSTGRES_PASSWORD=misskey
      - POSTGRES_USER=misskey
      - POSTGRES_DB=misskey
    volumes:
      - ./db:/var/lib/postgresql/data

networks:
  misskey_db:
    internal: true
  external_network:
```


## 方針

それぞれのコンテナは以下のノードに割り当てられるようにする
- pi41: dbとredis
- pi31,32,33: web
