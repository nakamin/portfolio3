# Stage 1: Build stage 依存関係をインストールするためのビルド環境を作成。必要なすべてのライブラリをインストールします。
# ベースイメージを指定
FROM jupyter/base-notebook:python-3.11 AS builder

# rootユーザーに切り替え
USER root

# システムパッケージの更新と必要なパッケージのインストール
RUN apt-get update && apt -y upgrade && \
    apt-get install -y \
    curl build-essential gcc libpq-dev && \ 
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# requirements.txtをコピー
COPY requirements.txt /tmp/requirements.txt

# Pythonパッケージのインストール（TA-Libはcondaでインストールしているためrequirements.txtから削除）
RUN pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Stage 2: Final stage 実行環境用の軽量イメージを作成。
# Stage 1でビルドした依存関係をCOPYで最終イメージに持ってきて、不要な開発ツールやキャッシュなどを排除します。
FROM jupyter/base-notebook:python-3.11

# rootユーザーに切り替え
USER root

# Stage 1 から必要なファイルをコピー
# COPY --from=builderは、最初のビルドステージ（builder）からファイルをコピーします。
# 最初の/opt/condaは、コピー元のディレクトリです。最初のステージでインストールされたconda環境を含んでいます。
# 最後の/opt/condaは、コピー先のパスであり、最終的なイメージにおける同じディレクトリにconda環境が配置されます。
COPY --from=builder /opt/conda /opt/conda

# 作業ディレクトリの作成と所有権の付与
RUN mkdir -p /home/jovyan/work && chown -R $NB_UID:$NB_GID /home/jovyan/work

# 必要に応じてJupyterのポートを開放
EXPOSE 8888

# デフォルトのユーザーに戻す
USER $NB_UID

# 作業ディレクトリを設定
WORKDIR /home/jovyan/work