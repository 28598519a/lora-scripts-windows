# LoRA interrogate script by @bdsqlsz

$v2 = 0 # load Stable Diffusion v2.x model / Stable Diffusion 2.x模型讀取
$sd_model = "./sd-models/sd_model.safetensors" # Stable Diffusion model to load: ckpt or safetensors file | 讀取的基礎SD模型, 保存格式 cpkt 或 safetensors
$model = "./output/LoRA.safetensors" # LoRA model to interrogate: ckpt or safetensors file | 需要調查關鍵字的LORA模型, 保存格式 cpkt 或 safetensors
$batch_size = 64 # batch size for processing with Text Encoder | 使用 Text Encoder 處理時的批量大小，默認16，推薦64/128
$clip_skip = 1 # use output of nth layer from back of text encoder (n>=1) | 使用文本編碼器倒數第 n 層的輸出，n 可以是大於等於 1 的整數


# Activate python venv
#.\venv\Scripts\activate
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"

$Env:HF_HOME = "huggingface"
$ext_args = [System.Collections.ArrayList]::new()

if ($v2) {
  [void]$ext_args.Add("--v2")
}

# run interrogate
python python/Scripts/accelerate.exe launch --num_cpu_threads_per_process=8 "./sd-scripts/networks/lora_interrogator.py" `
	--sd_model=$sd_model `
	--model=$model `
	--batch_size=$batch_size `
	--clip_skip=$clip_skip `
	$ext_args 

Write-Output "Interrogate finished"
Read-Host | Out-Null ;
