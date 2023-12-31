# GitlabRunnerデモ用サンプル
Gitlab, Gitlab Runnerの環境構築用です。

## サービス構成
GitlabとGitlab Runnerを連携させるために各コンテナを固定IPで起動します。
- Postgres  
  172.20.0.2
- Mail  
  172.20.0.3
- Gitlab  
  172.20.0.4
- Gitlab Runner  
  172.20.0.5

## コンテナ起動と初期セットアップ
### コンテナ起動
```bash
# いきなりupでもよいですが、念のため
docker-compose pull
# コンテナ起動
docker-compose up -d
```
### Gitlab Runnerコンテナに必要なソフトウェアインストール
```bash
# Gitlab Runnerのコンテナに入ります。
docker exec -it contrast_gitlab_demo.gitlab-runner bash
```
コンテナ内で
```bash
apt-get update
apt-get install -y vim
```
## Gitlabに接続
http://localhost:8080/ で接続します。  
root/passwordでログインします。

## Gitlab Runnerの登録
### Gitlab Runnerの登録用トークンについて
*Admin Area> Runners*  
**Register an Instance Runner**

**500エラーが出てしまう場合はページ最下部の補足を参照してください。**  
その他にグループレベル、プロジェクトレベルでRunnerを登録することもできます。適宜、環境や状況に合わせて選択してください。  

### Gitlab Runnerの登録
```bash
# Gitlab Runnerのコンテナに入ります。
docker exec -it contrast_gitlab_demo.gitlab-runner bash
```
コンテナ内で
```bash
gitlab-runner register -n \
  --url http://172.20.0.4 \
  --registration-token [REGISTRATION_TOKEN] \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner"
```
### Gitlab RunnerのDocker Executorをカスタマイズ
```bash
# Gitlab Runnerのコンテナに入ります。
docker exec -it contrast_gitlab_demo.gitlab-runner bash
```
コンテナ内で
```bash
vim /etc/gitlab-runner/config.toml
```
**以下4つを追加または変更します。**
- clone_url  
  コンテナ間通信のためdocker-compose.yml内での名前を指定します。
- network_mode  
  ネットワーク名は```docker network ls```で確認してください。  
  これは実施している環境（ディレクトリ）によって接頭辞が変わります。
- volumes  
  ```/var/run/docker.sock:/var/run/docker.sock```を値として追加します。
- pull_policy  
  ```if-not-present```を設定します。これによってホストにあるDockerイメージをpullすることができます。
```toml
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "docker-runner"
  url = "http://172.20.0.4"
  token = "[REGISTRATION_TOKEN]"
  executor = "docker"
  clone_url = "http://gitlab/" # これを追加します。
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    network_mode = "gitlabrunnersample_fixed_compose_network" # これを追加します。
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"] # 値を変更します。
    shm_size = 0
    pull_policy = "if-not-present" # これを追加します。
```

あとはGitlabのRunnerのところで、Gitlab Runnerが登録されていることを確認します。

## 補足
### Gitlabのポート番号を変える（8080->8081など）などでdown, up後にAdmin>Runnersで500エラーでどうしようもない時
```bash
gitlab-rails dbconsole --db main
```
```sql
gitlab=> UPDATE projects SET runners_token = null, runners_token_encrypted = null;
gitlab=> UPDATE projects SET runners_token = null, runners_token_encrypted = null;
gitlab=> UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
gitlab=> UPDATE application_settings SET runners_registration_token_encrypted = null;
gitlab=> UPDATE ci_runners SET token = null, token_encrypted = null;
```

## 後片付け
### コンテナ停止
```bash
# ボリュームも一緒に削除する場合
doker-compose down --volumes
```
