# Pythonの公式イメージをベースにする
FROM python:3.9-slim-bullseye

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

# .NET SDK をインストール（ランタイムも含まれる）
# 最新版は Microsoft の公式ドキュメントで確認してください。ここでは .NET 8.0 SDK の例。
# 参考: https://learn.microsoft.com/ja-jp/dotnet/core/install/linux-debian
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl && \
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --runtime dotnet && \
    ln -s /root/.dotnet/dotnet /usr/local/bin/dotnet



 
# Dockerfile: ILSpycmdのダウンロードと配置の部分

# 画像からバージョンとファイル名を取得
ARG ILSPY_VERSION="9.1.0.7988"
ARG ILSPY_RELEASE_DIR="v9.1"
ARG ILSPY_ZIP_FILE="ILSpy_selfcontained_${ILSPY_VERSION}-x64.zip"

RUN apt-get update && apt-get install -y unzip curl && \
    curl -f -sSL "https://github.com/icsharpcode/ILSpy/releases/download/${ILSPY_RELEASE_DIR}/${ILSPY_ZIP_FILE}" -o /tmp/ILSpy.zip && \
    ls -lh /tmp/ILSpy.zip && \
    unzip /tmp/ILSpy.zip -d /app/ilspy && \
    rm /tmp/ILSpy.zip  # ここが重要: 前の行のバックスラッシュの後に続ける







# Jadx のダウンロードと配置
# リリースバージョンはJadxのGitHubリリースページで確認してください
ARG JADX_VERSION="1.4.7" # 例: 最新の安定版
RUN apt-get update && apt-get install -y wget && \
    wget "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -O /tmp/jadx.zip && \
    unzip /tmp/jadx.zip -d /app/jadx && \
    rm /tmp/jadx.zip

# Jadx の実行ファイルに実行権限を付与
RUN chmod +x /app/jadx/bin/jadx
# Jadx をPATHに追加
ENV PATH="/app/jadx/bin:${PATH}"

# uncompyle6 のインストール (Python の依存関係インストールと同時に行っても良い)
# requirements.txt に uncompyle6 を追加するのがベストプラクティスですが、
# ここでは例として直接インストールします
#RUN pip install uncompyle6



# Flaskアプリケーションがリッスンするポートを公開
EXPOSE 5000

# アプリケーションを起動
CMD ["python", "app.py"]
