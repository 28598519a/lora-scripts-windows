$save_precision = "fp16" # precision in saving, default float | 保存精度, 可選 float、fp16、bf16, 默認 float
$new_rank = 4            # dim rank of output LoRA | dim rank等級, 默認 4
$model = "./output/lora_name.safetensors" # original LoRA model path need to resize, save as cpkt or safetensors | 需要調整大小的模型路徑, 保存格式 cpkt 或 safetensors
$save_to = "./output/lora_name_new.safetensors" # output LoRA model path, save as ckpt or safetensors | 輸出路徑, 保存格式 cpkt 或 safetensors
$device = "cuda"         # device to use, cuda for GPU | 使用 GPU跑, 默認 CPU
$verbose = 1             # display verbose resizing information | rank變更時, 顯示詳細信息
$dynamic_method = ""     # Specify dynamic resizing method, --new_rank is used as a hard limit for max rank | 動態調節大小，可選"sv_ratio", "sv_fro", "sv_cumulative",默認無
$dynamic_param = ""      # Specify target for dynamic reduction | 動態參數,sv_ratio模式推薦1~2, sv_cumulative模式0~1, sv_fro模式0~1, 比sv_cumulative要高

# Activate python env
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"

$Env:HF_HOME = "huggingface"
$ext_args = [System.Collections.ArrayList]::new()

if ($verbose) {
  [void]$ext_args.Add("--verbose")
}

if ($dynamic_method) {
  [void]$ext_args.Add("--dynamic_method=" + $dynamic_method)
}

if ($dynamic_param) {
  [void]$ext_args.Add("--dynamic_param=" + $dynamic_param)
}

# run resize
python python/Scripts/accelerate.exe launch --num_cpu_threads_per_process=8 "./sd-scripts/networks/resize_lora.py" `
	--save_precision=$save_precision `
	--new_rank=$new_rank `
	--model=$model `
	--save_to=$save_to `
	--device=$device `
	$ext_args 

Write-Output "Resize finished"
Read-Host | Out-Null ;
