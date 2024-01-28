python\python.exe -m pip install torch==2.1.2+cu118 torchvision==0.16.2+cu118 --index-url https://download.pytorch.org/whl/cu118

cd sd-scripts
..\python\python.exe -m pip install --upgrade -r requirements.txt
..\python\python.exe -m pip install -U -I --no-deps xformers==0.0.23.post1
..\python\python.exe -m pip install lycoris-lora lion-pytorch dadaptation

copy .\bitsandbytes_windows\*.dll ..\python\Lib\site-packages\bitsandbytes\
copy /y .\bitsandbytes_windows\cextension.py ..\python\Lib\site-packages\bitsandbytes\cextension.py
copy /y .\bitsandbytes_windows\main.py ..\python\Lib\site-packages\bitsandbytes\cuda_setup\main.py
