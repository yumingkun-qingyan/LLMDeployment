#!/bin/bash

MODEL_NAME=""
API_PORT=""
GUI_PORT=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model_name) MODEL_NAME="$2"; shift ;;
        --api_port) API_PORT="$2"; shift ;;
        --gui_port) GUI_PORT="$2"; shift ;;
        *) exit 1 ;;
    esac
    shift
done

if [ -z "$MODEL_NAME" ] || [ -z "$API_PORT" ] || [ -z "$GUI_PORT" ]; then
    exit 1
fi

if [ -f "$(pwd)/python_env/bin/python" ]; then
    PYTHON_EXEC="$(pwd)/python_env/bin/python"
    export PATH="$(pwd)/python_env/bin:$PATH"
else
    PYTHON_EXEC="python"
fi

if [ ! -d "./$MODEL_NAME" ]; then
    exit 1
fi

if ! ls core_ui.*.so 1> /dev/null 2>&1 && ! ls core_ui.*.pyd 1> /dev/null 2>&1; then
    echo "Core module missing."
    exit 1
fi

nohup $PYTHON_EXEC -m vllm.entrypoints.openai.api_server \
    --model "./$MODEL_NAME" \
    --served-model-name "$MODEL_NAME" \
    --port "$API_PORT" \
    --trust-remote-code \
    --gpu-memory-utilization 0.9 > vllm_server.log 2>&1 &

VLLM_PID=$!

cleanup() {
    kill $VLLM_PID
    exit
}
trap cleanup SIGINT SIGTERM

while true; do
    if curl -s "http://localhost:${API_PORT}/v1/models" > /dev/null; then
        break
    fi
    if ! ps -p $VLLM_PID > /dev/null; then
        exit 1
    fi
    sleep 5
done

rm -f core.py
$PYTHON_EXEC launch.py "$API_PORT" "$MODEL_NAME" "$GUI_PORT"