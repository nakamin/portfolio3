# GPU版
# Stage 1: Build stage
# ベースイメージを指定
FROM nvidia/cuda:12.1.1-base-ubuntu20.04 AS builder

# rootユーザーに切り替え
USER root

# 環境変数を定義
ENV NB_UID=1000
ENV NB_GID=100
ENV HOME=/home/jovyan

# システムパッケージの更新と必要なパッケージのインストール
RUN apt-get update && apt get install -y --no-install-recommends \
    curl \
    build-essential \
    gcc \
    libpq-dev \
    python3 \
    python3-pip \
    python3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# requirements.txtをコピー
COPY requirements.txt /tmp/requirements.txt

# Pythonパッケージのインストール（TA-Libはcondaでインストールしているためrequirements.txtから削除）
RUN pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    pip install jupyterlab && \
    rm /tmp/requirements.txt

# $PATHにインストール先を追加
ENV PATH=$PATH:/usr/local/bin/:/root/.local/bin

# CUDA 12.1
RUN pip install torch=2.4.1 torchvision=0.19.1 torchaudio=2.4.1 --index-url https://download.pytorch.org/whl/cu121

# 必要なディレクトリを作成
RUN mkdir -p $HOME/.local/share/jupyter && \
    mkdir -p $HOME/notebooks && \
    chown -R $NB_UID:$NB_GID $HOME

# Stage 2: Final stage
# Stage 1でビルドした依存関係をCOPYで最終イメージに持ってきて、不要な開発ツールやキャッシュなどを排除します。
FROM nvidia/cuda:12.1.1-base-ubuntu20.04

# rootユーザーに切り替え
USER root

# 環境変数を再定義
ENV NB_UID=1000
ENV NB_GID=100
ENV HOME=/home/jovyan

# Stage 1 から必要なファイルをコピー
COPY --from=builder /usr /usr
COPY --from=builder $HOME $HOME

# 作業ディレクトリの作成と所有権の付与
RUN mkdir -p /home/jovyan/notebooks && chown -R $NB_UID:$NB_GID /home/jovyan/notebooks
RUN mkdir -p /home/jovyan/.local/share/jupyter/runtime && \
    chown -R $NB_UID:$NB_GID /home/jovyan/.local

# 必要に応じてJupyterのポートを開放
EXPOSE 8888

# デフォルトのユーザーに戻す
USER $NB_UID

# 作業ディレクトリを設定
WORKDIR /home/jovyan/notebooks
# jupyterlabの起動コマンドを設定
CMD ["jupyter". "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]