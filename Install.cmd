python\python.exe -m pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116

cd sd-scripts
..\python\python.exe -m pip install --upgrade -r requirements.txt
..\python\python.exe -m pip install -U -I --no-deps https://github.com/C43H66N12O12S2/stable-diffusion-webui/releases/download/f/xformers-0.0.14.dev0-cp310-cp310-win_amd64.whl
..\python\python.exe -m pip install lion-pytorch locon dadaptation

copy .\bitsandbytes_windows\*.dll ..\python\Lib\site-packages\bitsandbytes\
copy /y .\bitsandbytes_windows\cextension.py ..\python\Lib\site-packages\bitsandbytes\cextension.py
copy /y .\bitsandbytes_windows\main.py ..\python\Lib\site-packages\bitsandbytes\cuda_setup\main.py
