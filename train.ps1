# Train data path | 設置訓練用模型、圖片
$pretrained_model = "./sd-models/model.ckpt" # base model path | 底模路徑 (pruned或full都行，不要使用vae)
$train_data_dir = "./train/Graf"             # train dataset path | 訓練數據集路徑
$reg_data_dir = ""                           # directory for regularization images | 正則化數據集路徑，默認不使用正則化圖像。

# Train related params | 訓練相關參數
$resolution = "512,512"      # image resolution w,h. 圖片分辨率，寬,高。支持非正方形，但必須是 64 倍數。
$batch_size = 2              # batch size | 建議2或4 (若VRAM不夠設1)
$max_train_epoches = 20      # max train epoches | 最大訓練 epoch
$save_every_n_epochs = 2     # save every n epochs | 每 N 個 epoch 保存一次
$network_dim = 32            # network dim | 常用 4~128，不是越大越好
$network_alpha = 16          # network alpha | 常用與 network_dim 相同的值或者採用較小的值，如 network_dim的一半 防止下溢。默認值為 1，使用較小的 alpha 需要提升學習率。
$clip_skip = 2               # clip skip | 一般Anime用 2 (因為NAI)
$noise_offset = 0            # noise offset | 在訓練中添加噪聲偏移來改良生成非常暗或者非常亮的圖像，推薦參數為0.1
$keep_tokens = 0             # keep heading N tokens when shuffling caption tokens | 在隨機打亂 tokens 時，保留前N個不變
$train_unet_only = 0         # train U-Net only | 僅訓練 U-Net，開啟這個會犧牲效果大幅減少顯存使用。6G顯存可以開啟
$train_text_encoder_only = 0 # train Text Encoder only | 僅訓練 文本編碼器

# Learning rate | 學習率
$lr = 1e-4 * $batch_size
$unet_lr = 1e-4 * $batch_size
$text_encoder_lr = 1e-5 * $batch_size
$lr_scheduler = "cosine_with_restarts" # "linear", "cosine", "cosine_with_restarts", "polynomial", "constant", "constant_with_warmup" | 學習率動態調整方式
$lr_warmup_steps = 0                   # warmup steps | 僅在 lr_scheduler 為 constant_with_warmup 時需要填寫這個值
$lr_restart_cycles = 1                 # cosine_with_restarts restart cycles | cosine調整重複次數，僅在 lr_scheduler 為 cosine_with_restarts 時起效。

# Output settings | 輸出設置
$output_name = "Graf"          # output model name | 模型保存名稱
$save_model_as = "safetensors" # model save ext | 模型保存格式 ckpt, pt, safetensors

# 其他設置
$network_weights = ""               # pretrained weights for LoRA network | 若需要從已有的 LoRA 模型上繼續訓練，請填寫 LoRA 模型路徑。
$min_bucket_reso = 256              # arb min resolution | arb 最小分辨率
$max_bucket_reso = 1024             # arb max resolution | arb 最大分辨率
$persistent_data_loader_workers = 0 # persistent dataloader workers | 保留加載訓練集的worker，減少每個 epoch 之間的停頓 (只差幾秒，沒必要，而且對內存需求較高)

# 優化器設置
$optimizer_type = "AdamW8bit" # "AdamW8bit", "Lion", "DAdaptation" | AdamW8bit : 8bit adam 優化器節省顯存，默認這個。部分 10 系老顯卡無法使用

# LoCon 訓練設置 (目前不建議使用)
$enable_locon_train = 0 # enable LoCon train | 啟用 LoCon 訓練 (Full Net LoRA)。啟用後 network_dim 和 network_alpha 應當選擇較小的值，比如 2~16
$conv_dim = 4           # conv dim | 類似於 network_dim，推薦為 4
$conv_alpha = 4         # conv alpha | 類似於 network_alpha，可以採用與 conv_dim 一致或者更小的值


# ============= DO NOT MODIFY CONTENTS BELOW | 請勿修改下方內容 =====================
# Activate python venv
#.\venv\Scripts\activate
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"

$Env:HF_HOME = "huggingface"
$ext_args = [System.Collections.ArrayList]::new()

if ($train_unet_only) {
  [void]$ext_args.Add("--network_train_unet_only")
}

if ($train_text_encoder_only) {
  [void]$ext_args.Add("--network_train_text_encoder_only")
}

if ($network_weights) {
  [void]$ext_args.Add("--network_weights=" + $network_weights)
}

if ($reg_data_dir) {
  [void]$ext_args.Add("--reg_data_dir=" + $reg_data_dir)
}

if ($optimizer_type -ieq "AdamW8bit") {
  [void]$ext_args.Add("--use_8bit_adam")
}

if ($optimizer_type -ieq "Lion") {
  [void]$ext_args.Add("--use_lion_optimizer")
}

if ($optimizer_type -ieq "DAdaptation") {
  [void]$ext_args.Add("--optimizer_type=" + $optimizer_type)
  [void]$ext_args.Add("--optimizer_args=`"decouple=True`"")
  $lr = 1
  $unet_lr = 1
  $text_encoder_lr = 0.5
}

if ($persistent_data_loader_workers) {
  [void]$ext_args.Add("--persistent_data_loader_workers")
}

if ($enable_locon_train) {
  $network_module = "locon.locon_kohya"
  [void]$ext_args.Add("--network_args")
  [void]$ext_args.Add("conv_dim=$conv_dim")
  [void]$ext_args.Add("conv_alpha=$conv_alpha")
}

# run train
python python/Scripts/accelerate.exe launch --num_cpu_threads_per_process=8 "./sd-scripts/train_network.py" `
  --enable_bucket `
  --pretrained_model_name_or_path=$pretrained_model `
  --train_data_dir=$train_data_dir `
  --output_dir="./output" `
  --logging_dir="./logs" `
  --resolution=$resolution `
  --network_module=networks.lora `
  --max_train_epochs=$max_train_epoches `
  --learning_rate=$lr `
  --unet_lr=$unet_lr `
  --text_encoder_lr=$text_encoder_lr `
  --lr_scheduler=$lr_scheduler `
  --lr_warmup_steps=$lr_warmup_steps `
  --lr_scheduler_num_cycles=$lr_restart_cycles `
  --network_dim=$network_dim `
  --network_alpha=$network_alpha `
  --output_name=$output_name `
  --train_batch_size=$batch_size `
  --save_every_n_epochs=$save_every_n_epochs `
  --mixed_precision="fp16" `
  --save_precision="fp16" `
  --seed="1337" `
  --cache_latents `
  --clip_skip=$clip_skip `
  --prior_loss_weight=1 `
  --max_token_length=225 `
  --caption_extension=".txt" `
  --save_model_as=$save_model_as `
  --min_bucket_reso=$min_bucket_reso `
  --max_bucket_reso=$max_bucket_reso `
  --keep_tokens=$keep_tokens `
  --xformers --shuffle_caption $ext_args

Write-Output "Train finished"
Read-Host | Out-Null ;
