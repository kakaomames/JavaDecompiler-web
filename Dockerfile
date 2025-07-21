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

# ILSpycmd のダウンロードと配置
# リリースバージョンはILSpycmdのGitHubリリースページで確認してください
ARG ILSPYCMD_VERSION="8.2.0-preview.2" # 例: 最新の安定版またはプレビュー版
RUN apt-get install -y unzip && \
    curl -sSL "https://github.com/icsharpcode/ILSpy/releases/download/v${ILSPYCMD_VERSION}/ILSpycmd-${ILSPYCMD_VERSION}.zip" -o /tmp/ILSpycmd.zip && \
    unzip /tmp/ILSpycmd.zip -d /app/ilspycmd && \
    rm /tmp/ILSpycmd.zip

# ILSpycmdをPATHに追加 (これにより、どこからでもdotnet /app/ilspycmd/ILSpycmd.dll で実行可能)
ENV PATH="/root/.dotnet:${PATH}"

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
