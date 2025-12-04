# 大模型部署
按照以下流程部署模型。
需求：linux环境。

## 1. 下载模型
在**联网环境**中执行
```
sh download_model.sh --model_name model_name --src source
```
其中source应该是

huggingface（在能连境外时使用，效果最稳定）

hf-mirror （不能连境外时使用，是上面那个的镜像，有的时候会不好用）

modelscope （仅在上面两个都不能用时使用）

之一。

model_name是一个 X/Y的格式，其中X是组织名，Y是模型名。

常用模型及它们对应的model_name如下：

**国产**

- 通义千问2.5-7b: Qwen/Qwen2.5-7B-Instruct

- 通义千问3-8b/32b/235b: Qwen/Qwen3-8B, Qwen/Qwen3-32B, Qwen/Qwen3-235B-A22B-Instruct-2507

- chatglm4.6: zai-org/GLM-4.6

- deepseek 3.2（据说比3.1有提升，但稳定性不好）: deepseek-ai/DeepSeek-V3.2

- deepseek 3.1: deepseek-ai/DeepSeek-V3.1-Terminus

- kimi k2: moonshotai/Kimi-K2-Thinking


**非国产**

    gpt-oss-20b/120b(目前为止最好用的推理模型): openai/gpt-oss-20b, openai/gpt-oss-120b

    Llama 4: meta-llama/Llama-4-Scout-17B-16E-Instruct, meta-llama/Llama-4-Maverick-17B-128E-Instruct

    mistral 3 small（欧洲最好的模型）: mistralai/Ministral-3-8B-Instruct-2512

    mistral 3 large: mistralai/Mistral-Large-3-675B-Instruct-2512



**OCR模型**

    腾讯混元：tencent/HunyuanOCR

    deepseek：deepseek-ai/DeepSeek-OCR

    百度paddle：PaddlePaddle/PaddleOCR-VL

    英伟达nemotron: nvidia/NVIDIA-Nemotron-Parse-v1.1 



## 2. 如果目标环境**没有联网**
如果目标环境可以联网，可以执行步骤3，速度会快很多。

在本地环境中先执行
```
sh download_python.sh。
```
它运行完毕后会在本目录下生成一个python_package.tar。

把整个目录，加上生成的这个tar文件一起拷贝到目标环境中。

然后在目标环境中执行install_python.sh。

## 3. 如果目标环境**有联网**

把整个目录拷贝到目标环境后执行
```
install_python_online.sh
```

## 4. 部署模型
全精度部署一个参数量为XB的模型需要大约2X GB的显存。

比如qwen2.5-7b大约需要14gb显存。

对于参数量很大（比如几百B）的模型，因为一张显卡无法装满，所以需要更多的显存。

在显存不足时可以选用低精度部署，会降低速度和表现。


在本目录下运行
```
sh deploy.sh --model_name model_name --api_port port1 --gui_port port2
```
运行结束后，在
```
http://127.0.0.1:port2/
```
访问gui。

在
```
http://127.0.0.1:port1/
```
调用api.
