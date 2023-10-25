# lora-scripts-windows
這是修改的訓練腳本，基於這兩個庫，一但安裝完成，則可以直接拿到其他Win電腦上運行<br>
https://github.com/kohya-ss/sd-scripts<br>
https://github.com/Akegarasu/lora-scripts

Note: sd-script 813 commits 對應 sd-script 0.6.5 version, 目前對於sdxl模型的訓練暫時沒打算立即跟進

## 安裝
**解壓縮python_310.rar**<br>
**執行Install.cmd** (如果因為網路問題沒裝成功就重新執行直到成功完成)

## 訓練
將pretrained_model、train_data_dir、output_name設定好並放入對應的主模型、訓練資料後，**執行train.ps1**

PS. Error caught was: No module named 'triton'忽視就好，這個是xformers 0.15新用到的套件，windows沒有，不影響訓練結果

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
   3. reg_data_dir (選用)
      - Repeats_Concept : \<number>\_\<class>
        - number可以設低一些，一般就是設1
        - class也是屬於關鍵詞，之後生圖的時候使用到這個關鍵詞才有用
      - 不需要打Tag
      - prior_loss_weight參數決定reg對訓練集的影響權重，1表示與訓練集相同 (可以考慮0.3)
      - reg用於泛化性
        - 正則化常用於處理複雜數據集，避免過擬合和欠擬合問題，提高泛化性
        - 在Training data不是很少的情況下 (低於30張)，不建議使用reg，可能會導致欠擬合，增加訓練時間也不一定能成功收斂 (尤其是訓練角色這種需要學習特別固定特徵的且很難描述出來的內容；ex: 臉型、身形，用了reg會導致訓練結果朝向reg的臉型及身形)
      - reg用於準確性
        - 正則化就是給機器一個參考圖片，讓它學習，因此正確使用正則化可以提高訓練準確性
        - 用於增強training data與reg都有的特徵，而只有reg有的特徵會被分離 (即不學；ex: training data只有臉，而reg放了全身，那麼學到的就是臉部特徵及特徵應該位於全身的哪個位置，而不會學到只有臉)，這種用於特徵分離的做法也可以拿來用在訓練背景LoRA之類的
3. **訓練成功的LoRA，在只使用單一LoRA的情況下，應該要適合在權重為1出圖，如果需要調高或調低LoRA調用權重，表示訓練錯誤**
4. 關於LoRA訓練速度及VRAM用量 (pytorch 2 + xformers 0.17)
   - 測試
      - 3.4 min / 1000 steps on RTX4070Ti (512*512)
      - 5.7G VRAM / 32dim, 30 images (如果顯卡同時有作為螢幕輸出，則還需要另外考慮這部分的VRAM占用)
   - 輸出模型的大小 (等比例，可直接計算)
      - dim128 : 144MB
      - dim32 : 36MB
      - dim8 : 9MB
5. epoch*repeats ≈ 50 ~ 100，具體情況看訓練的loss跟出圖測試，只要loss的曲線方向仍然向下都還可以試著繼續訓練
   - 根據訓練其他DeepLearning模型的經驗，train的loss進入抖動期前，vaild的loss會先向上，也就是overfitting會先發生，不過對於lora任務來說稍微overfitting其實是好事
   - Repeats看圖片數量決定，通常是5~8，對於圖片數量少的可能要設高一點 (但要考慮overfitting的問題)，另外多個Concept的話要考慮Repeats*ImageNum的平衡性及主次問題
   - Overfitting後，通常是手會先出問題，再來是身體的曲線、肢體數量，最後是背景、雜訊噪點 (但是通常最佳輸出會出現在手出問題後)
   - 要強調的一點是，loss不是越低越好，一來是可能overfitting，再來因為假設學習目標是A，但實際上你的訓練資料會含有A、B、C，因此目標是要在overfitting前學到最多的A與最少的B、C，這也是摳圖這種做法的核心原因 (所以其實還是得靠實際出圖，用肉眼判斷)
   - DAdaptAdam的epoch建議設AdamW的1~1.4倍 (ex: AdamW:10 epoch, DAdaptAdam: 12 or 14 epoch)
6. 關於LyCoris (locon、loha)
   - 不建議訓練locon、loha，需要更多的訓練時間、更大的model size，但結果通常明顯比lora差 (某些細節確實學的比較快，但不同細節的學習速度看起來很不平均)
   - 尤其是loha，除了在沒有overfitting時效果比lora差之外，與lora、locon相比，還非常容易overfitting (這也是訓練LyCoris需要用更低的network_dim的原因)
   - 由於這2種方法訓練了像素部分，增加了像素隨機性，對於角色這種需要強烈固定特徵的來說是非常不適合的，基本上除了畫風訓練，否則別用 (基本上看到一個角色model如果是用LyCoris的，改用LoRA做的話肯定能得到更好的結果)
   - loha因為使用了2張圖去算，所以實際上是平方操作，為了避免VRAM爆掉，設定的network_dim、conv_dim要設為locon設定的開根號，即√dim
   - 訓練LyCoris的lr要設低一點 (lora / locon / loha) : 1e-4 / 8e-5 / 5e-5
   - network_dim32 + conv_dim4 (lora / locon / loha) : 36 / 42 / 84 MB
   - speed (lora / locon / loha) : 1 / 1.44 / 2 倍的訓練時間

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
2. 訓練上通常有幾種作法
   - Folder
      - Repeats_Concept (ex: 5_角色名稱)
         1. Concept內的所有圖的元素會試圖被總結為該Concept (觸發詞)
         2. 如果Concept也有角色名稱，訓練結果有可能會比較穩定
      - Repeats_Concept_Class (ex: 5_角色名稱_類別)
         1. 類別名稱不影響，只是方便區分
         2. 對於是否有將相同類別的圖分Concept放，效果不確定
   - txt
      - 打全標
         1. txt開頭要打進觸發詞
         2. 常用這個，方便，也比較不會overfitting (如果不是選全標，epoch*repeats要低一點)
         3. 角色調用可能會需要打比較多Prompt，但通常是還好，畢竟有Tag自動關聯
      - 刪標 (b、c必需要--keep_tokens)
         1. 一種是只刪角色特徵 (沒刪全也還好，當全標簡化版看待就好)
         2. 另一種是只留觸發詞+下面列的那些保留類型的詞 (設白名單後一鍵刪除處理)
         3. 如果刪了下面寫的選擇保留的Tag，那觸發詞就要做對應的處理，像是[角色名稱 (類別名稱)] (ex: King George V (uniform)))
      - 不打標 (無txt)
         1. 等於用Concept名稱訓練，效果等同只在txt中打1個Tag並作為觸發詞
         2. 如果只是想產生固定服裝樣式的某個角色，這樣做已經很有效果
3. 關於刪Tag
   - 刪除的Tag
      - 角色基本特徵 (blonde hair、breasts、twintails、xxx eyes)
   - 選擇保留的Tag
      - 服裝 (uniform、miniskirt、swimsuit、hat、pantyhose、xxx clothes)
   - 保留的Tag (即使下面沒列的類型也不能刪，能刪的只有上面2種)
      - 人物數量 (1girl、solo、2girls、multiple girls)
      - 動作 (standing、sitting、lying、holding、arms up)
      - 視角 (looking at xxx)
      - 表情 (smile、tsurime)
      - 背景 (indoors、night、snow、chair、simple background、white background)
      - 圖片類型 (full body、upper body、close up)
4. 訓練資料的品質決定上限，注意訓練資料的品質，其次才是數量 (保質爭量)
   - 如果想還原特定畫風的人物，那最好少用一些其他畫風的該人物圖
   - 人物的正側面、衣飾、局部細節甚至特殊部位都能學會，如果要盡力還原，那麼需要有一些各種地方的細節圖片，但是佔比不能太大
   - 沒標註出來的Tag會被LoRA學進那張圖的其他Tag中 (像是背景如果沒Tagger相關Tag，那之後訓練出來的模型，可能就會在沒加相關Prompt的情況下生出這個背景)
5. LoRA訓練輸入目錄
   - 你可以有一個概念子文件夾或10個，但你必須至少有一個
   - 概念文件夾遵循以下格式:\<number>\_\<name>
      - \<number>決定了您的訓練腳本將在該文件夾上重複執行的次數
      - \<name>是裡面所有TXT Caption文件詞的總和，因此name會做為主要觸發詞
   - 指定根目錄來訓練，而非Repeats_Concept資料夾
   - 如果沒有TXT Caption文件，則lora將使用概念名稱作為觸發詞(標題)進行訓練<br>
![](https://user-images.githubusercontent.com/33422418/222901478-6b97e7d5-6192-4bea-b6c4-8d6f38d86967.png)
6. 供參考的分類方式
   - 先建2個資料夾sfw、nsfw，內部的分類用子資料夾應該差不多 (方便之後選擇訓練資料跟打標)
     - Tagger: Additional tags打 角色名稱 (或是觸發詞)
     <br>![](https://user-images.githubusercontent.com/33422418/222903603-9341423d-1750-4baa-bc68-ad05e51b4b6f.png)
   - nsfw/sfw資料集的3種可能的使用方式
     - nsfw內sex取出為一類，其餘皆為nsfw類，這2個Concept跟sfw的其他Concept放一起訓練 (目前先暫時建議選這個用法)
     - 單獨訓練sfw / nsfw
     - 取sfw 10~20%占比數量的nsfw圖片與sfw放在相同Concept中訓練 (因為nsfw占比太高的話，輸出圖片的布料可能會少)
   - 對於text類別，好抹的就用小畫家用附近的顏色把字大概抹一抹後，分到原本的類別去就行，不好抹的字少的話就打artist name、twitter username、signature這些tag上去後留著沒關係，字太多的話建議刪掉
   - 對於背景摳圖的問題，這個圖片少的話建議用小畫家抹一抹大概摳一下，圖片多的話不摳影響較小 (注意一下background類別就好)，如果有摳圖的話可能要打個simple background之類的tag上去
     - 這裡我提供一種不摳圖、不抹圖思路 (只是思路，沒實際測試過):
       1. 對背景非單色的訓練圖片裁減出角色部分丟training folder，原圖丟到對應的reg folder (如此就可以分離角色跟背景，甚至LoRA可以藉此學到角色跟背景的位置關係)
       2. 如果訓練素材足夠的情況下，訓練出第一版後，negative prompt填white background、simple background生成角色帶背景的圖 (甚至可以搞點別的，像是text之類的)，丟reg folder (如果用於生成的LoRA效果其實已經不錯，可以採類似第1點的方案，同樣裁一份到training folder擴充訓練資料)

## Tagger
建議使用WD14 Tagger而非DeepDanbooru<br>
https://github.com/toriato/stable-diffusion-webui-wd14-tagger

1. 直接在SD-webui的Extensions搜尋就行，裝好後關掉重開應該就會看到Tagger欄了
2. Interrogator建議選擇**wd14-swinv2-v2**
3. 打標的時候要勾Remove duplicated tag
4. 如果之後訓練出來的模型發現某種元素特別容易出現而且改Prompt也去不太掉，則要考慮針對性在含有該元素的訓練圖片打上那個Tag，讓LoRA可以學到那個Tag與對應的元素，這樣才不會融合進其他觸發詞中
