$save_precision = "fp16" # precision in saving, default float | 保存精度, 可選 float、fp16、bf16, 默認 float
$new_rank = 4            # dim rank of output LoRA | dim rank等級, 默認 4
$model = "./output/lora_name.safetensors" # original LoRA model path need to resize, save as cpkt or safetensors | 需要調整大小的模型路徑, 保存格式 cpkt 或 safetensors
$save_to = "./output/lora_name_new.safetensors" # output LoRA model path, save as ckpt or safetensors | 輸出路徑, 保存格式 cpkt 或 safetensors
$device = "cuda"         # device to use, cuda for GPU | 使用 GPU跑, 默認 CPU
$verbose = 1             # display verbose resizing information | rank變更時, 顯示詳細信息


# Activate python venv
#.\venv\Scripts\activate
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"

$Env:HF_HOME = "huggingface"
$ext_args = [System.Collections.ArrayList]::new()

if ($verbose) {
  [void]$ext_args.Add("--verbose")
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
