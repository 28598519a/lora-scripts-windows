# lora-scripts-windows
這是修改的訓練腳本，基於這兩個庫，一但安裝完成，則可以直接拿到其他Win電腦上運行<br>
https://github.com/kohya-ss/sd-scripts<br>
https://github.com/Akegarasu/lora-scripts

## 安裝
**解壓縮python_310.rar**<br>
**執行Install.cmd** (如果因為網路問題沒裝成功就重新執行直到成功完成)

## 訓練
將pretrained_model、train_data_dir、output_name設定好並放入對應的主模型、訓練資料後，**執行train.ps1**

1. 需要改的參數pretrained_model、train_data_dir、output_name
   - network_dim一般32就好，不用128
   - network_alpha就0.25~0.5倍的dim值 (ex:16)
   - Batch_Size建議設2或4，訓練的學習曲線可能會比較穩定 (VRAM不夠就設1)
2. 需要放好
   1. pretrained_model
      - 應該重要的是主模型能理解Tag就好，至於主模型本身是什麼畫風可能不太重要
      - 主模型選擇Full或是Pruned都可以，但是結果應該差不多 (考慮到VRAM問題，建議選擇Pruned)
   2. train_data_dir
      - kohya-ss/sd-scripts會自動把大圖做downsampling+cropping，所以不自己先裁減好圖片也可以 (不確定這樣品質如何，也許訓練結果較好也說不定)
      - Repeats_Concept，這個Concept會作為主觸發詞，圖片放裡面
      - Repeats_Concept : \<number>\_\<name>
        - ex: 5\_A B\_C，則5會是每個epoch的圖片重複次數，A B C都會是主觸發詞
        - 一般是這樣做 \<number>\_\<name>\_\<class>，name是角色，class是概念分類 (ex: 6_miku_swimsuit)
        - 如果要學的Concept會跟某種Tag重複且指的是不同東西，那最好把Concept取個特別名字以做區分避免Tag混淆
3. seed參數用於重現結果，如果設定相同且相同seed，應該會得到非常接近的模型
4. 對於512*512設定，每增加1張圖約需要4.8MB VRAM (圖片是否有先裁減不影響)
   - 測試
      - 7.4 min / 1000 steps on RTX4070Ti
      - 7.7G VRAM / 32dim, 30 images (如果顯卡同時有作為螢幕輸出，則還需要另外考慮這部分的VRAM占用)
      - 7.1G VRAM / 16 dim, 30 images
   - 輸出模型的大小 (等比例，可直接計算)
      - dim128 : 144MB
      - dim32 : 36MB
      - dim8 : 9MB
5. epoch*repeats = 約200，但具體情況看訓練的loss，只要loss的曲線方向仍然向下都還可以繼續訓練
   - 根據訓練其他DeepLearning模型的經驗，train的loss進入抖動期前，vaild的loss會先向上，也就是overfitting會先發生，不過對於lora任務來說稍微overfitting其實是好事
   - Repeats看圖片數量決定，通常是5~8，對於圖片數量少的可能要設高一點，另外多個Concept的話要考慮Repeats*ImageNum的平衡性及主次問題

## Training Data
1. 訓練上通常有2種作法
   - 利用Concept作為觸發詞，那個Concept底下所有的概念跟Tag會被學進Concept中，而且那些tag也會是觸發詞，輸入到那些詞的時候，對像是換衣服或動作等應該有用 (不能--keep_tokens，而且要訓練到所有Tag都成為觸發詞)，此種方式將訓練目標設定在Concept上，由LoRA在訓練的過程中自己總結該Concept資料夾下的圖片概念，成為觸發詞 (由於定義上比較模糊，而且取決於txt中Tagger的品質及LoRA自己的學習總結，對於是否會發生觸發詞融合，帶有運氣成分)
   - 透過在txt中打進特定的Tag做為觸發詞，同時刪除所有與角色特徵有關的Tag，讓那些被刪除的Tag及沒打上的Tag的概念被學進觸發詞中  (必需要--keep_tokens，明確定義觸發詞跟排除詞)，這種方式可以明確的定義出角色與其他觸發詞 (雖然明確定義出了學習目標，盡力避免了觸發詞融合，但預處理上很麻煩)
2. 訓練資料的品質決定上限，注意訓練資料的品質，其次才是數量 (保質爭量)
   - 如果想還原特定畫風的人物，那最好少用一些其他畫風的該人物圖
   - 人物的正側面、衣飾、局部細節甚至特殊部位都能學會，如果要盡力還原，那麼需要有一些各種地方的細節圖片，但是佔比不能太大
   - 沒標註出來的Tag會被LoRA學進那張圖的其他Tag中 (像是背景如果沒Tagger相關Tag，那之後訓練出來的模型，可能就會在沒加相關Prompt的情況下生出這個背景)
3. LoRA訓練輸入目錄
   - 你可以有一個概念子文件夾或10個，但你必須至少有一個
   - 概念文件夾遵循以下格式:\<number>\_\<name>
      - \<number>決定了您的訓練腳本將在該文件夾上重複執行的次數
      - \<name>是裡面所有TXT Caption文件詞的總和，因此name會做為主要觸發詞
   - 指定根目錄來訓練，而非Repeats_Concept資料夾
   - 如果沒有TXT Caption文件，則lora將使用概念名稱作為觸發詞(標題)進行訓練<br>
![](https://user-images.githubusercontent.com/33422418/222901478-6b97e7d5-6192-4bea-b6c4-8d6f38d86967.png)
4. 供參考的分類方式
   - 先建2個資料夾sfw、nsfw裡面的Repeats_Concept資料夾相同 (方便之後打標跟訓練)
     - sfw: Additional tags打 角色名稱
     - nsfw:  Additional tags打 角色名稱, nsfw
   - nsfw/sfw資料集的4種可能的使用方式
     - nsfw內不分類，直接以nsfw作為一個Concept跟sfw放一起訓練
     - sfw、nsfw直接合併一起訓練
     - 單獨訓練sfw / nsfw
     - 取20%的nsfw圖片混進sfw中訓練
   - 如果要排除不放入訓練資料時的優先順序: text > multiple > background > sex<br>
![](https://user-images.githubusercontent.com/33422418/222903603-9341423d-1750-4baa-bc68-ad05e51b4b6f.png)

## Tagger
建議使用WD14 Tagger而非DeepDanbooru<br>
https://github.com/toriato/stable-diffusion-webui-wd14-tagger

1. 直接在SD-webui的Extensions搜尋就行，裝好後關掉重開應該就會看到Tagger欄了
2. Interrogator建議選擇**wd14-swinv2-v2**
3. 打標的時候要勾Remove duplicated tag
4. 如果之後訓練出來的模型發現某種元素特別容易出現而且改Prompt也去不太掉，則要考慮針對性在含有該元素的訓練圖片打上那個Tag，讓LoRA可以學到那個Tag與對應的元素，這樣才不會融合進其他觸發詞中
