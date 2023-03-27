$save_precision = "fp16" # precision in saving, default float | 保存精度, 可選 float、fp16、bf16, 默認 float
$model_1 = "./output/lora_name1.safetensors" # original LoRA model path need to merge (cpkt / safetensors) | 需要合併的模型1路徑
$model_2 = "./output/lora_name2.safetensors" # original LoRA model path need to merge (cpkt / safetensors) | 需要合併的模型2路徑 (模型1、模型2的rank應該相同)
$save_to = "./output/lora_name_merge.safetensors" # output LoRA model path, save as ckpt or safetensors | 輸出路徑, 保存格式 cpkt 或 safetensors
$ratio_1 = 0.5 # model_1 weight | model_1權重
$ratio_2 = 0.5 # model_2 weight | model_2權重 (建議 $ratio_1 + $ratio_2 = 1)

$merge_to_sd = 0 # enable merge the LoRA model into the Stable Diffusion model | 將LoRA合併至Stable-Diffusion模型中
$pretrained_model = "./sd-models/model.ckpt" # base model path | 底模路徑

# Activate python env
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"
$Env:HF_HOME = "huggingface"
$ext_args = [System.Collections.ArrayList]::new()

if ($merge_to_sd) {
  [void]$ext_args.Add("--sd_model" + $pretrained_model)
}

# run merge
python python/Scripts/accelerate.exe launch --num_cpu_threads_per_process=8 "./sd-scripts/networks/merge_lora.py" `
	--save_precision=$save_precision `
	--models=$model_1 $model_2 `
	--ratios=$new_rank `
	--save_to=$save_to `
	$ext_args 

Write-Output "Merge finished"
Read-Host | Out-Null ;
