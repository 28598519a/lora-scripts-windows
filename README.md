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
      - 主模型選擇的優先順序:
         - Novel AI > AnythingV3.0 > AnythingV4.5 (Purned ≥ Full)
         - Full或是Pruned結果其實很接近 (VRAM占用也相同)
         - 推測Mix越多的模型越容易overfitting，原因不明
   2. train_data_dir
      - 通過指定enable_bucket參數，kohya-ss/sd-scripts會自動把圖片分類至各種min/max_bucket_reso間的解析度訓練，所以不自己先裁減好圖片也可以 (不確定這樣品質如何，也許訓練結果較好也說不定)
      - Repeats_Concept，這個Concept會作為主觸發詞，圖片放裡面 (網路上有些教學會說這在有txt的情況下是不起觸發作用的，但實際上是會的)
      - Repeats_Concept : \<number>\_\<name>
        - ex: 5\_A\_B C，則5會是每個epoch的圖片重複次數，A B會是主觸發詞 (ex: 4_Kamisato_Ayaka)
        - 一般是這樣做 \<number>\_\<name> \<class>，name是類別或角色名稱 (空格要用_替換)，class是用在reg (正則化圖片)用的大類 (ex: 6_miku 1girl, 5_bikini swimsuit)
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
5. epoch*repeats ≈ 100~200 (建議從100開始)，具體情況看訓練的loss跟出圖測試，只要loss的曲線方向仍然向下都還可以試著繼續訓練
   - 根據訓練其他DeepLearning模型的經驗，train的loss進入抖動期前，vaild的loss會先向上，也就是overfitting會先發生，不過對於lora任務來說稍微overfitting其實是好事
   - 要強調的一點是，loss不是越低越好，loss跟fitting沒有絕對關係，可能loss低結果underfitting，也可能overfitting (通常是overfitting，除非用了正則化之類的方法)，最終還是要靠觸發詞、model權重出圖測試，用肉眼判斷為準 (以下面的圖為例，結果最好的是綠色那條v19)
   - Repeats看圖片數量決定，通常是5~8，對於圖片數量少的可能要設高一點，另外多個Concept的話要考慮Repeats*ImageNum的平衡性及主次問題
   ![](https://user-images.githubusercontent.com/33422418/224232520-89815474-0bfb-4b84-8f10-8bdae35692b4.png)

## Training Data
1. LoRA對txt中Tag的處理
   1. 每一輪LoRA會將txt中的Tag (打亂)選取前4個做為觸發詞，剩下的元素排除 (類似摳圖)，這個時候剩下的沒被Tag出來的元素會被學進這4個Tag中
      - Tag會學到自己的樣式 + 剩下的元素 + 與另外3個Tag的關係
      - 每一輪的這4個Tag之間會產生一定的關聯性 (過度關聯則會導致觸發詞融合；同時Tag不能亂加，否則產生關聯後結果不一定是好的)
   2. 當txt的Tag中有主模型識別不出來的Tag，則因為少學了自己，這就有了把剩下元素學進這個Tag的感覺
   3. LoRA學到的那些Tag，若之後用來跑圖的主模型也有這個Tag，那LoRA會透過跟主模型的這個Tag合併的方式來起作用 (因此要注意Tag污染的風險，這也是某些訓練做法會要求刪除Tag的部分原因)
   4. 瞭解了上面說明LoRA的學習特性為基礎後，就可以用來設計訓練方式，基本上可以總結為以下幾個機制
      - Tag間的自動關聯
      - Tag對自己的樣式學習
      - Tag對剩餘元素的學習
2. 訓練上通常有5種作法 (這部分其實不太確定，但供參考)
   - 單Concept
      1. 利用Concept作為觸發詞 (角色名稱)，不放任何txt (效果等同只在txt中打1個Tag並作為觸發詞)。該Concept內的所有圖的元素會試圖被總結為該Concept，通常如果只是想產生固定服裝樣式的某個角色，這樣做已經很有效果
      2. 利用Concept作為觸發詞 (角色名稱) ，txt直接用tagger完成打標。那個Concept底下所有的概念跟tag會被學進Concept中以最多的那幾個tag呈現出來。而那些txt中的tag也會是觸發詞，輸入到那些詞的時候，對像是換衣服或動作等應該有用 (要訓練到所有tag都成為觸發詞)
   - 多Concept
      1. 利用Concept作為觸發詞 (類別名稱)，txt直接用tagger完成打標 (可以不打角色名稱)
      2. 部分Concept作為觸發詞 (類別名稱)，txt直接用tagger完成打標 (可以不打角色名稱)，然後用白名單的方式，只保留觸發詞+一些角度、姿勢描述，其他砍光 (算是下面第5種方式的簡化版，必需要--keep_tokens)
      3. Concept僅做分類，隨便取個不會被打出來的詞。再來透過在txt中打進特定的Tag做為觸發詞 [角色名稱 (類別名稱)] (ex: King George V (uniform))，同時用Tagger Editor刪掉與我們目標觸發詞相關描述的所有Tag，讓那些被刪除的Tag及沒打上的Tag的概念被學進觸發詞中 (必需要--keep_tokens)
3. 訓練資料的品質決定上限，注意訓練資料的品質，其次才是數量 (保質爭量)
   - 如果想還原特定畫風的人物，那最好少用一些其他畫風的該人物圖
   - 人物的正側面、衣飾、局部細節甚至特殊部位都能學會，如果要盡力還原，那麼需要有一些各種地方的細節圖片，但是佔比不能太大
   - 沒標註出來的Tag會被LoRA學進那張圖的其他Tag中 (像是背景如果沒Tagger相關Tag，那之後訓練出來的模型，可能就會在沒加相關Prompt的情況下生出這個背景)
4. LoRA訓練輸入目錄
   - 你可以有一個概念子文件夾或10個，但你必須至少有一個
   - 概念文件夾遵循以下格式:\<number>\_\<name>
      - \<number>決定了您的訓練腳本將在該文件夾上重複執行的次數
      - \<name>是裡面所有TXT Caption文件詞的總和，因此name會做為主要觸發詞
   - 指定根目錄來訓練，而非Repeats_Concept資料夾
   - 如果沒有TXT Caption文件，則lora將使用概念名稱作為觸發詞(標題)進行訓練<br>
![](https://user-images.githubusercontent.com/33422418/222901478-6b97e7d5-6192-4bea-b6c4-8d6f38d86967.png)
5. 供參考的分類方式
   - 先建2個資料夾sfw、nsfw，內部的分類用子資料夾應該差不多 (方便之後選擇訓練資料跟打標)
     - Tagger: Additional tags打 角色名稱 (或是觸發詞)
   - nsfw/sfw資料集的3種可能的使用方式
     - nsfw內sex取出為一類，其餘皆為nsfw類，這2個Concept跟sfw的其他Concept放一起訓練 (目前先暫時建議選這個用法)
     - 單獨訓練sfw / nsfw
     - 取sfw 10~20%占比數量的nsfw圖片與sfw放在相同Concept中訓練 (因為nsfw占比太高的話，輸出圖片的布料可能會少)
   - 對於text類別，好抹的就用小畫家用附近的顏色把字大概抹一抹後，分到原本的類別去就行，不好抹的就留著沒關係，通常Tagger是會自動把text, user name等Tag打出來的，除非text圖的比例太高 (把repeats設低點調整一下就好)，不然通常不影響訓練結果
   - 對於背景摳圖的問題，這個圖片少的話建議用小畫家抹一抹大概摳一下，圖片多的話不摳基本上不影響 (注意一下background類別就好)，如果有摳圖的話可能要打個simple background之類的tag上去<br>
![](https://user-images.githubusercontent.com/33422418/222903603-9341423d-1750-4baa-bc68-ad05e51b4b6f.png)

## Tagger
建議使用WD14 Tagger而非DeepDanbooru<br>
https://github.com/toriato/stable-diffusion-webui-wd14-tagger

1. 直接在SD-webui的Extensions搜尋就行，裝好後關掉重開應該就會看到Tagger欄了
2. Interrogator建議選擇**wd14-swinv2-v2**
3. 打標的時候要勾Remove duplicated tag
4. 如果之後訓練出來的模型發現某種元素特別容易出現而且改Prompt也去不太掉，則要考慮針對性在含有該元素的訓練圖片打上那個Tag，讓LoRA可以學到那個Tag與對應的元素，這樣才不會融合進其他觸發詞中
