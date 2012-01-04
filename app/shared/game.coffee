# ------ 役職一覧
# 基本役職
exports.jobs=["Human","Werewolf","Diviner","Psychic","Madman","Guard","Couple","Fox",
# 特殊役職?
"Poisoner","BigWolf","TinyFox",
# 特殊役職2
"Devil","ToughGuy"
# るる鯖で見つけた役職
"Fanatic","Immoral"
# 桃栗基本特殊役職
"Bat","Noble","Slave","Magician","Spy","WolfDiviner",
# 桃栗期間限定役職
"Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Spy2","Copier"
]
# ここには入らない役職
# Light, Neet

# 人外
exports.nonhumans=["Werewolf","Fox","BigWolf","TinyFox","WolfDiviner","MadWolf","Devil"]

# チームたち
exports.teams=
	Human:["Human","Diviner","Psychic","Guard","Couple","Poisoner","ToughGuy","Noble","Slave","Magician","Fugitive","Merchant","QueenSpectator","MadWolf","Liar","Copier"]
	Werewolf:["Werewolf","Madman","BigWolf","Fanatic","Spy","WolfDiviner","Spy2"]
	Fox:["Fox","TinyFox","Immoral"]
	Bat:["Bat"]
	Devil:["Devil"]
	Neet:["Neet"]

# 役職ルールたち 役職人数一覧を返す（Humanは向こうで補完）
normal1=(number)->
  ret={}
  #狼
  ret.Werewolf=1
  if number>=8
    ret.Werewolf++
    if number>=13
      ret.Werewolf++
      if number>=18
        ret.Werewolf++
        if number>=22
          ret.Werewolf++
          if number>=27
            ret.Werewolf++
  ret.Diviner=1	#占い
  if number>4
    ret.Psychic=1 #霊能
  if number>=6
    ret.Madman=1 #狂人
    ret.Guard=1 #狩人
    if number>=16
      ret.Madman++
      ret.Guard++
  if number>=12
    ret.Couple=2 #共有
    if number>=18
      ret.Couple++
  if number>=11
    ret.Fox=1 #狐
    if number>=17
      ret.Fox++
  ret
normal2=(number)->
  ret={}
  # 人狼
  ret.Werewolf=1
  if number>=8
    ret.Werewolf++
    if number>=16
     ret.Werewolf++
     if number>=20
       ret.Werewolf++
       if number>=25
         ret.Werewolf++
         if number>=29
           ret.Werewolf++
  ret.Diviner=1	#占い師
  if number>4
    ret.Psychic=1	#霊能者
  if number>=10
    ret.Madman=1	#狂人
    if number>=28
      ret.Madman++
  if number>=11
    ret.Guard=1	#狩人
  if number>=13
    ret.Couple=2	#共有者
    if number>=28
      ret.Couple++
  if number>=15
    ret.Fox=1	#狐
  ret

exports.jobrules=[
  {
    name:"普通配役"
    rule:[
      {
        name:"普通1"
        title:"少人数でも楽しめる配役。"
        rule:normal1
      }
      {
        name:"普通2"
        title:"一般的な配役。"
        rule:normal2
      }
    ]
  }
  {
    name:"桃栗配役"
    rule:[
      {
        name:"こうもり"
        title:"こうもりが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Bat=1
          if number>=10
            ret.Bat++
            if number>=16
              ret.Bat++
          ret
      }
      {
        name:"貴族奴隷"
        title:"貴族奴隷が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Noble=1
          ret.Slave=1
          if ret.Couple>=2
            # 共有者ポジション
            ret.Couple=0
          if number>=14
            ret.Slave++
            if number>=20
              ret.Slave++
              if number>=23
                ret.Noble++
          ret
      }
      {
        name:"魔術師"
        title:"魔術師が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Magician=1
          ret
      }
      {
        name:"スパイ"
        title:"スパイが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Spy=1
          if number<10 && ret.Madman>0
            ret.Madman--
          ret
      }
      {
        name:"人狼占い"
        title:"人狼占いが入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Werewolf--
          ret.WolfDiviner=1
          if number>=7
            ret.Fox++
          ret
      }
      {
        name:"商人"
        title:"商人が入る配役。"
        rule:(number)->
          ret=normal1 number
          ret.Merchant=1
          ret
      }
    ]
  }
  {
    name:"その他"
    rule:[
      {
        name:"狂った世界"
        title:"狂人が多い。"
        rule:(number)->
          ret={}
          count=3
          ret.Werewolf=1
          ret.Diviner=1
          ret.Guard=1
          if number>=9
            ret.Werewolf++
            count++
            if number>=15
              ret.Werewolf++
              count++
          if number>=10
            ret.Psychic++
            count++
          if number>=12
            ret.Fox++
            count++
          ret.Madman=number-count	#残り全部狂人
          ret
      }
    ]
  }
]
# ルール関数を得る
exports.getrulefunc=(name)->
	names= name.split "."
	obj=SS.shared.game.jobrules
	for branch in names	#.区切りでオブジェクト名
		obj=obj.filter((x)->x.name==branch)[0]?.rule
		unless obj	# そんな配役は見つからない
			return
	unless typeof obj =="function"
		#配列でない
		return
	obj

# 
exports.jobinfo=
	Human:
		name:"村人陣営"
		color:"#00CC00"
		Human:
			name:"村人"
			color:"#dddddd"
		Diviner:
			name:"占い師"
			color:"#00b3ff"
		Psychic:
			name:"霊能者"
			color:"#bb00ff"
		Guard:
			name:"狩人"
			color:"#969ad4"
		Couple:
			name:"共有者"
			color:"#ffffab"
		Poisoner:
			name:"埋毒者"
			color:"#853c24"
		Noble:
			name:"貴族"
			color:"#ffff00"
		Slave:
			name:"奴隷"
			color:"#1417d9"
		Magician:
			name:"魔術師"
			color:"#f03eba"
		Fugitive:
			name:"逃亡者"
			color:"#e8b279"
		Merchant:
			name:"商人"
			color:"#e06781"
		QueenSpectator:
			name:"女王観戦者"
			color:"#faeebe"
		Liar:
			name:"嘘つき"
			color:"#a3e4e6"
		Copier:
			name:"コピー"
			color:"#ffffff"
		Light:
			name:"デスノート"
			color:"#2d158c"					
		MadWolf:
			name:"狂人狼"
			color:"#847430"
		ToughGuy:
			name:"タフガイ"
			color:"#ff5900"
		
		
		
	Werewolf:
		name:"人狼陣営"
		color:"#DD0000"
		Werewolf:
			name:"人狼"
			color:"#220000"
		Madman:
			name:"狂人"
			color:"#ffbb00"
		BigWolf:
			name:"大狼"
			color:"#660000"
		Spy:
			name:"スパイ"
			color:"#ad5d28"
		WolfDiviner:
			name:"人狼占い"
			color:"#5b0080"
		Spy2:
			name:"スパイⅡ"
			color:"#d3b959"
		Fanatic:
			name:"狂信者"
			color:"#94782b"
		
		
	Fox:
		name:"妖狐陣営"
		color:"#934293"
		Fox:
			name:"妖狐"
			color:"#934293"
		TinyFox:
			name:"子狐"
			color:"#dd81f0"
		Immoral:
			name:"背徳者"
			color:"#5c2f5c"
			
		
	Bat:
		name:"こうもり"
		color:"#000066"
		Bat:
			name:"こうもり"
			color:"#000066"
	Devil:
		name:"悪魔くん"
		color:"#735f9e"
		Devil:
			name:"悪魔くん"
			color:"#735f9e"
		
	Neet:
		name:"ニート"
		color:"#aaaaaa"
		Neet:
			name:"ニート"
			color:"#aaaaaa"
