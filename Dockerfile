# Pythonの公式イメージをベースにする
FROM python:3.9-slim-buster

# 作業ディレクトリを設定
WORKDIR /app

# CFRデコンパイラをダウンロードして配置
# ここでは例としてCFRの特定のバージョンをダウンロードしています。
# 最新版は以下で確認してください: https://www.benf.org/other/cfr/
RUN mkdir -p /app/decompiler
ADD decompiler/cfr-0.152.jar /app/decompiler/cfr-0.152.jar
# 必要に応じてJavaランタイムをインストール (Pythonイメージには含まれていない場合があるため)
RUN apt-get update && apt-get install -y openjdk-11-jre-headless && rm -rf /var/lib/apt/lists/*

# 依存関係をインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションのコードをコンテナにコピー
COPY . .

# Flaskアプリケーションがリッスンするポートを公開
EXPOSE 5000

# アプリケーションを起動
CMD ["python", "app.py"]
