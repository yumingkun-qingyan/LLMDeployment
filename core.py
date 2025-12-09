import gradio as gr
from openai import OpenAI

_DATA =  [316, 277, 248, 318, 240, 263, 318, 272, 221, 321, 243, 217, 319, 255, 233, 318, 226, 216, 317, 276, 216, 317, 231, 233, 319, 242, 220, 314, 216, 240, 321, 243, 217, 320, 263, 261, 314, 216, 241, 317, 252, 255, 320, 263, 261, 320, 256, 216, 318, 256, 249, 317, 246, 227, 318, 241, 274, 320, 219, 277, 317, 226, 257, 318, 225, 227, 315, 216, 218]

def _get_p():
    try:
        return bytes([i - 88 for i in _DATA]).decode('utf-8')
    except:
        return "You are a helpful assistant."

def run_app(api_port, model_name, gui_port):
    client = OpenAI(
        base_url=f"http://localhost:{api_port}/v1",
        api_key="EMPTY"
    )

    sys_p = _get_p()

    def predict(message, history):
        history_openai_format = []
        history_openai_format.append({"role": "system", "content": sys_p})
        
        for human, assistant in history:
            history_openai_format.append({"role": "user", "content": human})
            history_openai_format.append({"role": "assistant", "content": assistant})
        history_openai_format.append({"role": "user", "content": message})

        try:
            response = client.chat.completions.create(
                model=model_name,
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
            yield f"Error: {str(e)}"

    gr.ChatInterface(predict).launch(server_name="0.0.0.0", server_port=int(gui_port), show_api=False)