#!/bin/bash

# =================================================================
# 脚本名称: download_model.sh
# 功能: 根据指定源下载模型到当前目录下的同名文件夹中
# 用法: sh download_model.sh --model_name <模型ID> --src <源>
# =================================================================

MODEL_NAME=""
SRC=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model_name) MODEL_NAME="$2"; shift ;;
        --src) SRC="$2"; shift ;;
        *) echo "❌ 未知参数: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$MODEL_NAME" ] || [ -z "$SRC" ]; then
    echo "❌ 错误: 缺少必要参数。"
    echo "用法示例: sh download_model.sh --model_name Qwen/Qwen2.5-7B-Instruct --src hf-mirror"
    exit 1
fi

echo "========================================"
echo "准备下载模型: $MODEL_NAME"
echo "使用源: $SRC"
echo "保存位置: ./$MODEL_NAME"
echo "========================================"

case $SRC in
    huggingface)
        if ! command -v huggingface-cli &> /dev/null; then
            echo "❌ 错误: 未找到 huggingface-cli。"
            echo "请运行: pip install -U huggingface_hub"
            exit 1
        fi
        
        unset HF_ENDPOINT
        echo "🚀 正在从 HuggingFace 官方下载..."
        huggingface-cli download --resume-download "$MODEL_NAME" --local-dir "./$MODEL_NAME" --local-dir-use-symlinks False
        ;;

    hf-mirror)
        if ! command -v huggingface-cli &> /dev/null; then
            echo "❌ 错误: 未找到 huggingface-cli。"
            echo "请运行: pip install -U huggingface_hub"
            exit 1
        fi

        echo "🚀 正在从 HF-Mirror (镜像) 下载..."
        export HF_ENDPOINT=https://hf-mirror.com
        huggingface-cli download --resume-download "$MODEL_NAME" --local-dir "./$MODEL_NAME" --local-dir-use-symlinks False
        ;;

    modelscope)
        if ! command -v modelscope &> /dev/null; then
            echo "❌ 错误: 未找到 modelscope 命令行工具。"
            echo "请运行: pip install -U modelscope"
            exit 1
        fi

        echo "🚀 正在从 ModelScope 下载..."
        modelscope download --model "$MODEL_NAME" --local_dir "./$MODEL_NAME"
        ;;

    *)
        echo "❌ 错误: 无效的 source 类型。"
        echo "可选值: huggingface, hf-mirror, modelscope"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo "✅ 下载完成！模型已保存在 ./$MODEL_NAME"
else
    echo "❌ 下载失败，请检查网络或模型名称是否正确。"
fi