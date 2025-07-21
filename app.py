from flask import Flask, render_template, request, send_file
import subprocess
import os
import uuid

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
DECOMPILED_FOLDER = 'decompiled'
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)
if not os.path.exists(DECOMPILED_FOLDER):
    os.makedirs(DECOMPILED_FOLDER)

# CFRデコンパイラのパス (Dockerコンテナ内のパス)
CFR_PATH = 'decompiler/cfr-0.152.jar' # お使いのCFRのバージョンに合わせてください

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return 'No file part'
    file = request.files['file']
    if file.filename == '':
        return 'No selected file'
    if file:
        filename = str(uuid.uuid4()) + os.path.splitext(file.filename)[1] # ユニークなファイル名
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        # デコンパイルの実行
        # 例: java -jar cfr.jar input.jar --outputdir output/
        output_dir = os.path.join(DECOMPILED_FOLDER, os.path.splitext(filename)[0])
        os.makedirs(output_dir, exist_ok=True)
        try:
            # subprocess.runは、実行されたプロセスの終了を待つ
            # check=True: 0以外の終了コードが返された場合にCalledProcessErrorを発生させる
            result = subprocess.run([
                'java', '-jar', CFR_PATH, filepath, '--outputdir', output_dir
            ], capture_output=True, text=True, check=True)
            print("CFR stdout:", result.stdout)
            print("CFR stderr:", result.stderr)

            # デコンパイル結果（.javaファイルなど）をZIP化して返す、などの処理
            # 例として、ここではデコンパイルされたファイルへのパスを返す
            # 実際には、複数のファイルがある場合はzip化して返すのが良いでしょう。
            decompiled_files = [f for f in os.listdir(output_dir) if f.endswith('.java')]
            if decompiled_files:
                # 最初のJavaファイルを返す例 (実際はZIP化が一般的)
                return send_file(os.path.join(output_dir, decompiled_files[0]), as_attachment=True)
            else:
                return f"Decompilation successful, but no .java files found in {output_dir}. CFR Output: {result.stdout}"

        except subprocess.CalledProcessError as e:
            return f"Decompilation failed: {e.stderr}"
        except Exception as e:
            return f"An error occurred: {str(e)}"
        finally:
            # 一時ファイルのクリーンアップ
            os.remove(filepath)
            # shutil.rmtree(output_dir) # デバッグ中はコメントアウトしてもOK

    return 'Something went wrong.'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0') # Docker環境ではhost='0.0.0.0'が必要
