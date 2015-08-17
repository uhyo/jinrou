# gameのgamelogs一览
    {
      id:(id)	//自分のID
      type:(type)	//自分的职业
      event:(event name)	//起こったこと
      target:(target?)	//対象のID（あれば）
      flag:(String?)	//補助的な情報（あれば）
      id:(Number)	//日付（自動的に記録）
    }
    
eventごとに列挙。

## 全体系

### job
役職の対象を選択した
* target: 相手のID

### found
死んだ
* flag: 死因

### transform
役職が変化した
* flag: 新しい役職

### bitten
噛まれた（死んだかどうかは問わない）

### vote
投票した
* target: 投票先ID

### getprize
称号を手に入れた
* flag: 称号ID


## 占卜师系

### divine
占った

* target: 相手のID
* flag: そ的职业

### cursekill
呪殺した

* target: 呪殺先のID

## 猎人
###GJ
GJした

* target: 护卫先

## 埋毒者
### poisonkill
毒で殺した

* target: 殺した相手

## 猫又
### catraise
蘇生させた
* target: もともとの蘇生相手
* flag:成功ならtrue 失敗ならfalse 誤爆なら誤爆先のID

## 小狐
### foxdivine
占った
* target: 占い相手
* flag: 成功ならtrue 失敗ならfalse

## 贵族
### nobleavoid
奴隶を身代わりにした

## 奴隶
### slavevictim
贵族の身代わりになった

## 魔术师
### raise
蘇生させた
* target: 蘇生相手
* flag:成功ならtrue 失敗ならfalse

## 人狼占卜师
### wolfdivine
占った

* target: 相手のID

## 逃亡者
### runto
逃亡した
* target: 逃亡先のID

## 商人
### sendkit
商品を送った
* target: 相手のID
* flag:送ったもの

## 骗子
### liardivine
占った
* target: 相手のID

## 圣职者
### holyGJ
無事守った

* target: 护卫先
* flag:本来の死因

## 王子
### princeCO
処刑を回避した

## 超常现象研究者
### PIdivine
占った

*target: 占い先
* flag:人外を発見したかどうか

## 魔女
### witchraise
蘇生した

*target: 蘇生先

### witchkill
殺害した

*target: 札がイサキ

## 二重身
### dopplemove
死んだので移動した
*target: 移動先ID
* flag:そ的职业

## 犬
### dogkill
飼い主を噛んだ
*target: 飼い主ID
* flag:そ的职业
