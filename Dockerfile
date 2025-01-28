# Stage 1: Build stage
# ベースイメージを指定
FROM nvidia/cuda:12.1.1-base-ubuntu20.04 AS builder

# rootユーザーに切り替え
USER root

# 環境変数を定義
ENV NB_UID=1000
ENV NB_GID=100

# システムパッケージの更新と必要なパッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
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
ENV PATH=$PATH:/usr/local/bin:/root/.local/bin

# CUDA 12.1
RUN pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu121

# Stage 2: Final stage
# Stage 1でビルドした依存関係をCOPYで最終イメージに持ってきて、不要な開発ツールやキャッシュなどを排除します。
FROM nvidia/cuda:12.1.1-base-ubuntu20.04

# rootユーザーに切り替え
USER root

# 環境変数を再定義
ENV NB_UID=1000
ENV NB_GID=100

# Stage 1 から必要なファイルをコピー
# nvidia/cuda ベースには conda が含まれていない
# builderステージでインストールしたPython関連の環境を最終ステージに引き継ぐ
COPY --from=builder /usr /usr

# 作業ディレクトリの作成と権限設定
RUN mkdir -p /home/jovyan/work && chown -R $NB_UID:$NB_GID /home/jovyan/work

# 必要に応じてJupyterのポートを開放
EXPOSE 8888

# JupyterLabの起動コマンドを設定
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]

# デフォルトのユーザーに戻す
USER $NB_UID

# 作業ディレクトリを設定
WORKDIR /home/jovyan/work