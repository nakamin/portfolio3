# GPU版
FROM nvidia/cuda:12.1.1-base-ubuntu22.04

# システムパッケージの更新と必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    vim \
    gcc \
    libpq-dev \
    python3.11 \
    python3-pip \
    python3.11-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# requirements.txtをコピー
COPY requirements.txt /tmp/requirements.txt

# Pythonパッケージのインストール
RUN pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt && \
    pip install jupyterlab ipykernel && \
    rm /tmp/requirements.txt

# CUDA 12.1
RUN pip install torch==2.4.1 torchvision==0.19.1 torchaudio==2.4.1 --index-url https://download.pytorch.org/whl/cu121

# 作業ディレクトリを設定
WORKDIR /notebooks

# jupyterlabの起動コマンドを設定
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]