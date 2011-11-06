class Game
	constructor:(@id)->
		@logs=[]
	setrule:(rule)->@rule=rule
	#成功:true 失敗:false
	setplayers:(joblist,playerids,cb)->
		jnumber=0
		for job,num of joblist
			jnumber+=num
		if jnumber!=playerids.length
			# 数が合わない
			return false
		if @rule.scapegoat=="on"
			playerids.push -1
		@players=[]
		jobs=
			Human:Human
			Werewolf:Werewolf
			Diviner:Diviner
			
		# ひとり決める
		i=0
		jobstep= =>
			if i++>=playerids.length
				# 全部終了
				cb true
			r=Math.floor Math.random()*playerids.length	# プレイヤーid
			for job,num of joblist
				SS.server.user.userData r,null,(user)=>
					@players.push new jobs[job] r,user.name
					# ひとり決めたので次へ
					jobstep()
				if num>1
					joblist[job]--
				else
					delete joblist[job]
				break
		
		jobstep()
		
		
		
###
logs:[{
	mode:"day"(昼) / "system"(システムメッセージ) /  "wolf"(狼) / "heaven"(天国)
	comment: String
},...]
rule:{
    number: Number # プレイヤー数
    scapegoat : "on"(身代わり君が死ぬ） "off"(参加者が死ぬ) "no"(誰も死なない)
  }
###
class Player
	constructor:(@id,@name)->
class Human extends Player
class Werewolf extends Player
class Diviner extends Player

games={}

exports.actions=
	newGame: (room,rule)->
		game=new Game room.id,rule
		games[room.id]=game
		
		
