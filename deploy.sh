#!/bin/bash

# =================================================================
# 脚本名称: deploy.sh
# 功能: 启动 vLLM API 服务并拉起 Gradio Web UI
# 用法: sh deploy.sh --model_name <模型目录名> --api_port <端口> --gui_port <端口>
# =================================================================

MODEL_NAME=""
API_PORT=""
GUI_PORT=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model_name) MODEL_NAME="$2"; shift ;;
        --api_port) API_PORT="$2"; shift ;;
        --gui_port) GUI_PORT="$2"; shift ;;
        *) echo "❌ 未知参数: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MODEL_NAME" ] || [ -z "$API_PORT" ] || [ -z "$GUI_PORT" ]; then
    echo "❌ 错误: 缺少必要参数。"
    echo "用法: sh deploy.sh --model_name Qwen/Qwen2.5-7B-Instruct --api_port 8000 --gui_port 7860"
    exit 1
fi

if [ -f "$(pwd)/python_env/bin/python" ]; then
    PYTHON_EXEC="$(pwd)/python_env/bin/python"
    export PATH="$(pwd)/python_env/bin:$PATH"
else
    PYTHON_EXEC="python"
fi

echo "========================================"
echo "正在启动部署流程..."
echo "模型路径: ./$MODEL_NAME"
echo "API 端口: $API_PORT"
echo "GUI 端口: $GUI_PORT"
echo "========================================"

if [ ! -d "./$MODEL_NAME" ]; then
    echo "❌ 错误: 找不到模型目录 ./$MODEL_NAME"
    echo "请先使用 download_model.sh 下载模型。"
    exit 1
fi

cat > web_ui_launcher.py <<EOF
import gradio as gr
from openai import OpenAI
import time

client = OpenAI(
    base_url="http://localhost:${API_PORT}/v1",
    api_key="EMPTY"
)

def predict(message, history):
    history_openai_format = []
    for human, assistant in history:
        history_openai_format.append({"role": "user", "content": human})
        history_openai_format.append({"role": "assistant", "content": assistant})
    history_openai_format.append({"role": "user", "content": message})

    try:
        response = client.chat.completions.create(
            model="${MODEL_NAME}",
            messages=history_openai_format,
            stream=True,
            temperature=0.7
        )
        partial_message = ""
        for chunk in response:
            if chunk.choices[0].delta.content is not None:
                partial_message += chunk.choices[0].delta.content
                yield partial_message
    except Exception as e:
        yield f"❌ Error: {str(e)}"

print("正在启动 Gradio 界面，端口: ${GUI_PORT}")
gr.ChatInterface(predict).launch(server_name="0.0.0.0", server_port=${GUI_PORT})
EOF

echo "🚀 正在启动 vLLM API 服务器 (后台运行)..."
echo "日志将输出到: vllm_server.log"

nohup $PYTHON_EXEC -m vllm.entrypoints.openai.api_server \
    --model "./$MODEL_NAME" \
    --served-model-name "$MODEL_NAME" \
    --port "$API_PORT" \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 > vllm_server.log 2>&1 &

VLLM_PID=$!

cleanup() {
    echo "正在关闭服务..."
    kill $VLLM_PID
    rm -f web_ui_launcher.py
    exit
}
trap cleanup SIGINT SIGTERM

echo "⏳ 等待模型加载 (可能需要几分钟)..."
while true; do
    if curl -s "http://localhost:${API_PORT}/v1/models" > /dev/null; then
        echo "✅ vLLM API 已就绪！"
        break
    fi
    if ! ps -p $VLLM_PID > /dev/null; then
        echo "❌ vLLM 启动失败，请查看 vllm_server.log"
        exit 1
    fi
    sleep 5
done

echo "🚀 正在启动 Web UI..."
$PYTHON_EXEC web_ui_launcher.py