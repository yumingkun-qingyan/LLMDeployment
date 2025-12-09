import sys
import os
import core

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(1)
        
    api_port = sys.argv[1]
    model_name = sys.argv[2]
    gui_port = sys.argv[3]

    core.run_app(api_port, model_name, gui_port)