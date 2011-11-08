class Game
	constructor:(@id)->
		@logs=[]
	setrule:(rule)->@rule=rule
	#成功:null
	setplayers:(joblist,players,cb)->
		jnumber=0
		for job,num of joblist
			jnumber+=parseInt num
		if jnumber!=players.length
			# 数が合わない
			cb "プレイヤー数が不正です(#{jnumber}/#{players.length})"
			return
		if @rule.scapegoat=="on"
			players.push {
				userid:-1
				name:"身代わりくん"
			}
		@players=[]
			
		# ひとり決める
		for job,num of joblist
			i=0
			while i++<num
				r=Math.floor Math.random()*players.length
				pl=players[r]
				@players.push new jobs[job] pl.userid,pl.name
		cb null
			
		
		
		
###
logs:[{
	mode:"day"(昼) / "system"(システムメッセージ) /  "wolf"(狼) / "heaven"(天国) / "prepare"(開始前)
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

# 仕事一覧
jobs=
	Human:Human
	Werewolf:Werewolf
	Diviner:Diviner


exports.actions=
#内部用
	newGame: (room,rule)->
		game=new Game room.id,rule
		games[room.id]=game

#ゲーム開始処理
#成功：null
	gameStart:(roomid,query,cb)->
		game=games[roomid]
		unless game?
			cb "そのゲームは存在しません"
			return
		SS.server.game.rooms.oneRoom roomid,(room)->
			if room.error? 
				cb room.error
				return
			unless room.mode=="waiting"
				# すでに開始している
				cb "そのゲームは既に開始しています"
				return
			game.setrule {
				number: room.players.length
				scapegoat : query.scapegoat
			}
			
			joblist={}
			for job of jobs
				joblist[job]=query[job]	# 仕事の数
			
			game.setplayers joblist,room.players,(result)->
				unless result?
					# プレイヤー初期化に成功
					M.rooms.update {id:roomid},{$set:{mode:"playing"}}
					cb null
					console.log game
				else
					cb result
		
	speak: (comment)->
		
		
