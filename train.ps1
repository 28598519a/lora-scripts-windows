# Train data path | 設置訓練用模型、圖片
$pretrained_model = "./sd-models/model.ckpt" # base model path | 底模路徑 (pruned或full都行，不要使用vae)
$train_data_dir = "./train/Graf"             # train dataset path | 訓練數據集路徑
$reg_data_dir = ""                           # directory for regularization images | 正則化數據集路徑，默認不使用正則化圖像。

# Output settings | 輸出設置
$output_name = "Graf"          # output model name | 模型保存名稱
$save_model_as = "safetensors" # model save ext | 模型保存格式 ckpt, pt, safetensors

# Train related params | 訓練相關參數
$resolution = "512,512"           # image resolution w,h. 圖片分辨率，寬,高。支持非正方形，但必須是 64 倍數。
$batch_size = 2                   # batch size | 建議2或4 (若VRAM不夠設1)
$max_train_epoches = 12           # max train epoches | 最大訓練 epoch
$save_every_n_epochs = 2          # save every n epochs | 每 N 個 epoch 保存一次
$network_dim = 32                 # network dim | 常用 4~128，不是越大越好
$network_alpha = 16               # network alpha | 常用與 network_dim 相同的值或者採用較小的值，如 network_dim 的一半 防止下溢。默認值為 1，使用較小的 alpha 需要提升學習率。
$clip_skip = 2                    # clip skip | 一般Anime用 2 (因為NAI)
$keep_tokens = 0                  # keep heading N tokens when shuffling caption tokens | 在隨機打亂 tokens 時，保留前N個不變
$mixed_precision = "fp16"         # "no, fp16, bf16" | 混和精度。30系列及之後的卡可以試試bf16
$sampler = ""                     # "ddim, euler, euler_a" | 預設值ddim
$train_unet_only = $false         # train U-Net only | 僅訓練 U-Net，開啟這個會犧牲效果大幅減少顯存使用。6G顯存可以開啟
$train_text_encoder_only = $false # train Text Encoder only | 僅訓練 文本編碼器
$noise_offset = 0                 # noise offset | 在訓練中添加噪聲偏移來生成非常暗或者非常亮的圖像，推薦參數為0.1。0為不啟用 (可能會造成色溫偏移，不建議使用)
$min_snr_gamma = 0                # minimum signal-to-noise ratio (SNR) value for gamma-ray | 伽馬射線事件的最小信噪比（SNR）值，用於增加訓練穩定性，推薦參數為5。0為不啟用 (不建議跟DAdaptation一起使用)
$flip_aug = $false                # data augmentation by horizontal flip | 對訓練資料做水平翻轉來得到2倍訓練資料。默認不使用

# Learning rate | 學習率
$lr = 1e-4 * $batch_size               # 也可以試epoch 14配 [Math]::Round([Math]::Sqrt($batch_size),4)
$unet_lr = 1e-4 * $batch_size
$text_encoder_lr = 1e-5 * $batch_size
$lr_scheduler = "cosine_with_restarts" # "linear", "cosine", "cosine_with_restarts", "polynomial", "constant", "constant_with_warmup" | 學習率動態調整方式
$lr_warmup_steps = 0                   # warmup steps | 學習率預熱步數，lr_scheduler 為 constant 或 adafactor 時該值需要設為0
$lr_restart_cycles = 1                 # cosine_with_restarts restart cycles | cosine調整重複次數，僅在 lr_scheduler 為 cosine_with_restarts 時起效。

# LoRA Block Weight | LoRA分層訓練
$block_weight_lr = $false                   # enable LoRA Block Weight for learning rates | 啟用指定LoRA分層學習率。默認不使用 (即weight_lr = lr*weight)
$down_lr_weight = "1,1,1,1,1,1,1,1,1,1,1,1" # IN | 指定12個值。lora: 1,2,4,5,7,8。lycoris: 0~11 (設0為刪除該層)
$mid_lr_weight = "1"                        # MID | 指定1個值。
$up_lr_weight = "1,1,1,1,1,1,1,1,1,1,1,1"   # OUT | 指定12個值。lora: 3~11。lycoris: 0~11
$block_weight_dim = $false                  # enable LoRA Block Weight for dims | 啟用指定LoRA分層network dim。默認不使用
$block_dims = "4,32,32,4,32,32,4,32,32,4,4,4,32,4,4,4,32,32,32,32,32,32,32,32,32"   # network block dim | 指定25個值。lora: 1,2,4,5,7,8,12,16~24。lycoris: 0~24
$block_alphas = "1,16,16,1,16,16,1,16,16,1,1,1,16,1,1,1,16,16,16,16,16,16,16,16,16" # network block alpha | 指定25個值 (常用 block_dims 的一半)

# 其他設置
$network_weights = ""                    # pretrained weights for LoRA network | 若需要從已有的 LoRA 模型上繼續訓練，請填寫 LoRA 模型路徑。
$min_bucket_reso = 256                   # arb min resolution | arb 最小分辨率
$max_bucket_reso = 1024                  # arb max resolution | arb 最大分辨率
$persistent_data_loader_workers = $false # persistent dataloader workers | 保留加載訓練集的worker，減少每個 epoch 之間的停頓 (只差幾秒，沒必要，而且對內存需求較高)
$log_as_outputname = $true               # Add output_name on log name prefix | 將log保存名稱開頭加上模型保存名稱。默認值為當前時間

# 優化器設置
$optimizer_type = "DAdaptAdam" # "AdamW8bit", "Lion", "DAdaptAdam"

# LyCORIS 訓練設置
$enable_lycoris_train = $false # enable LyCORIS train | 啟用 LyCORIS 訓練 (Full Net LoRA)。啟用後 network_dim 和 network_alpha 應選擇較小的值，比如 2~16
$algo = "lora"                 # LyCORIS network algo | LyCORIS 網絡算法。可選 lora、loha (lora即為locon)
$conv_dim = 4                  # conv dim | 類似於 network_dim，推薦為 4
$conv_alpha = 1                # conv alpha | 類似於 network_alpha，可以採用與 conv_dim 一致或者更小的值


# ============= DO NOT MODIFY CONTENTS BELOW | 請勿修改下方內容 =====================
# Activate python env & disable windows triton error
$Env:PATH = "C:\Windows\system32;.\python;.\python\Scripts"
$Env:HF_HOME = "huggingface"
$Env:XFORMERS_FORCE_DISABLE_TRITON = "1"
$network_module = "networks.lora"
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

if ($flip_aug) {
  [void]$ext_args.Add("--flip_aug")
}

if ($sampler) {
  [void]$ext_args.Add("--sample_sampler=" + $sampler)
}

if ($optimizer_type -ieq "DAdaptAdam") {
  [void]$ext_args.Add("--optimizer_args")
  [void]$ext_args.Add("decouple=True")
  [void]$ext_args.Add("weight_decay=0.01")
  [void]$ext_args.Add("betas=0.9,0.99")
  $lr_scheduler = "constant"
  $lr = 1
  $unet_lr = 1
  $text_encoder_lr = 1
}

if ($noise_offset) {
  [void]$ext_args.Add("--noise_offset=" + $noise_offset)
}

if ($min_snr_gamma) {
  [void]$ext_args.Add("--min_snr_gamma=" + $min_snr_gamma)
}

if ($persistent_data_loader_workers) {
  [void]$ext_args.Add("--persistent_data_loader_workers")
}

if ($log_as_outputname) {
  [void]$ext_args.Add("--log_prefix=" + $output_name + '_')
}

# network_args相關的要擺在這之後
if ($enable_lycoris_train -or $block_weight_lr -or $block_weight_dim) {
  [void]$ext_args.Add("--network_args")
}

if ($enable_lycoris_train) {
  $network_module = "lycoris.kohya"
  [void]$ext_args.Add("conv_dim=$conv_dim")
  [void]$ext_args.Add("conv_alpha=$conv_alpha")
  [void]$ext_args.Add("algo=$algo")
}

if ($block_weight_lr) {
  [void]$ext_args.Add("down_lr_weight=$down_lr_weight")
  [void]$ext_args.Add("mid_lr_weight=$mid_lr_weight")
  [void]$ext_args.Add("up_lr_weight=$up_lr_weight")
}

if ($block_weight_dim) {
  [void]$ext_args.Add("block_dims=$block_dims")
  [void]$ext_args.Add("block_alphas=$block_alphas")
}

# run train
python python/Scripts/accelerate.exe launch --num_cpu_threads_per_process=8 "./sd-scripts/train_network.py" `
  --enable_bucket `
  --pretrained_model_name_or_path=$pretrained_model `
  --train_data_dir=$train_data_dir `
  --output_dir="./output" `
  --logging_dir="./logs" `
  --resolution=$resolution `
  --network_module=$network_module `
  --max_train_epochs=$max_train_epoches `
  --learning_rate=$lr `
  --unet_lr=$unet_lr `
  --text_encoder_lr=$text_encoder_lr `
  --lr_scheduler=$lr_scheduler `
  --lr_warmup_steps=$lr_warmup_steps `
  --lr_scheduler_num_cycles=$lr_restart_cycles `
  --optimizer_type=$optimizer_type `
  --network_dim=$network_dim `
  --network_alpha=$network_alpha `
  --output_name=$output_name `
  --train_batch_size=$batch_size `
  --save_every_n_epochs=$save_every_n_epochs `
  --mixed_precision=$mixed_precision `
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
