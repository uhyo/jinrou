
makePrize=->
	prizes={}
	# まず勝利回数による賞を作る
	for job,prs of wincountprize
		for num,name of prs
			prizes["wincount_#{job}_#{num}"]=name
	# 次に何かをカウントして合計する賞を作る
	for type,obj of counterprize
		for num,name of obj.names
			prizes["#{type}_#{num}"]=name
	prizes


# 勝利回数による賞
wincountprize=
	Human:
		5:"凡人"
		10:"凡骨の意地"
		20:"探偵"
		30:"アイドル"
		40:"将軍"
		50:"王者"
		100:"フリーダム"
		150:"英雄"
	Diviner:
		5:"精霊の代弁者"
		10:"精霊の紡ぎ手"
		20:"輝ける道士"
		30:"神の紡ぎ手"
		50:"亜空間が見えた者"
		100:"現人神"
	Psychic:
		5:"ツクヨミ"
		10:"魂を呼ぶ者"
		30:"時の継承者"
		50:"巫女"
		100:"シャーマンキング"
# 敗北回数による賞
losecountprize=
	Human:
		20: "堕落者"
	Diviner:
		20: "占い詐欺師"
	Psychic:
		20: "小田霧響子"
		
###
特殊な回数カウント系称号
称号名:
	names:
		5:"5回の称号"
	func:(game)->	#gameDBデータを渡されるのでカウント数を返す falseとかnullは0
###
# 補助関数
Object.defineProperty Array.prototype,"sum",{
	value:(callback)->
		@map(callback).reduce ((a,b)->a+b),0
}
# gameからプレイヤーオブジェクトを拾う
getpl=(game,userid)->
	game.players.filter((x)->x.id==userid)[0]
getplreal=(game,userid)->
	game.players.filter((x)->x.realid==userid)[0]

counterprize=
	# 呪殺
	cursekill:
		names:
			5:"スナイパー"
			15:"狐の天敵"
			30:"魔弾の狙撃手"
			50:"疾風怒濤の極大射程"
		func:(game,userid)->
			# 呪殺を数える
			game.gamelogs.filter((x)->x.id==userid && x.event=="cursekill").length
	# GJ判定
	GJ:
		names:
			5:"防御の達人"
			10:"キーパー"
			30:"精霊の守護者"
			50:"仁王"
			100:"守護神"
		func:(game,userid)->
			game.gamelogs.filter((x)->x.id==userid && x.event=="GJ").length
	# 2日目昼に吊られた
###
	day2hanged:
		names:
			5:"???"
		func:(game,userid)->
			game.gamelogs.filter((x)->
				x.id==userid && x.event=="found" && x.flag=="punish" && x.day==2
			).length
	# 生き残った日数合計
	alivedays:
		names:
			50:"???50"
			150:"???150"
		func:(game,userid)->
			pl=getplreal game,userid
			if pl.dead || !pl.winner
				0
			else
				game.day
###


prizes=makePrize()	# 賞の一覧 {"prize1":"賞1","prize2","賞2"} というようにIDと名前の辞書

# 内部用
exports.actions=
	checkPrize:(userid,cb)->
		console.log "checking: #{userid}"
		# あるuseridのユーザーの賞をチェックする
		M.games.find({"players.realid":userid}).toArray (err,docs)->
			# 自分が参加したゲームを全て出す
			result=[]	# 賞の一覧
			# 勝敗数に関係する称号
			# 勝った試合のみ抜き出して自分だけにする
			mes=docs.map((x)->x.players.filter((pl)->pl.realid==userid)[0])
			wins=mes.filter((x)->x.winner)
			loses=mes.filter((x)->x.winner==false)
			for team,jobs of SS.shared.game.teams
				for job in jobs
					count=wins.filter((x)->x.originalType==job).length
					if count>0 && wincountprize[job]?
						for num in Object.keys(wincountprize[job])
							# 少ないほうから順に称号チェック
							if num<=count
								result.push "wincount_#{job}_#{num}"
							else
								break
					count=loses.filter((x)->x.originalType==job).length
					if count>0 && losecountprize[job]?
						for num in Object.keys(losecountprize[job])
							# 少ないほうから順に称号チェック
							if num<=count
								result.push "losecount_#{job}_#{num}"
							else
								break						
			# カウント称号
			for prizename,obj of counterprize
				count=docs.sum (game)->obj.func game,userid
				for num in Object.keys(obj.names)
					# 昇順
					if num<=count
						result.push "#{prizename}_#{num}"
					else
						break
			console.log "#{userid} : #{JSON.stringify result}"
			cb result
						
	
	prizeName:(prizeid)->prizes[prizeid]	# IDを名前に
	prizeQuote:(prizename)->"≪#{prizename}≫"
			
###
・役職ごとの勝利回数賞
"wincount_(役職名)_(回数)" というIDをつける
例） "wincount_Diviner_5"
・役職ごとの敗北回数賞
"losecount_(役職名)_(回数)" というIDをつける
例) "losecount_Human_20"

・カウント系称号
"(称号名)_(回数)" というIDをつける
例） "cursekill_5"
###
