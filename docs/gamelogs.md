# gameのgamelogs一覧
    {
      id:(id)	//自分のID
      type:(type)	//自分の役職
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


## 占い師系

### divine
占った

* target: 相手のID
* flag: その役職

### cursekill
呪殺した

* target: 呪殺先のID

## 狩人
###GJ
GJした

* target: 護衛先

## 埋毒者
### poisonkill
毒で殺した

* target: 殺した相手

## 子狐
### foxdivine
占った
* target: 占い相手
* flag: 成功ならtrue 失敗ならfalse

## 貴族
### nobleavoid
奴隷を身代わりにした

## 奴隷
### slavevictim
貴族の身代わりになった

## 魔術師
### raise
蘇生させた
* target: 蘇生相手
* flag:成功ならtrue 失敗ならfalse

## 人狼占い
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

## 嘘つき
### liardivine
占った
* target: 相手のID

## 聖職者
### holyGJ
無事守った

* target: 護衛先
* flag:本来の死因

## プリンス
### princeCO
処刑を回避した

## 超常現象研究者
### PIdivine
占った

*target: 占い先
* flag:人外を発見したかどうか

## ドッペルゲンガー
### dopplemove
死んだので移動した
*target: 移動先ID
* flag:その役職
