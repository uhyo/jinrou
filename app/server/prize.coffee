
makePrize=->
	prizes={}
	# まず勝利回数による賞を作る
	for job,prs of wincountprize
		for num,name of prs
			prizes["wincount_#{job}_#{num}"]=name
	for job,prs of losecountprize
		for num,name of prs
			prizes["losecount_#{job}_#{num}"]=name
	# 次に何かをカウントして合計する賞を作る
	for prizeobjs in [counterprize,allcounterprize,allplayersprize]
		for type,obj of prizeobjs
			for num,name of obj.names
				prizes["#{type}_#{num}"]=name
	# 単品の賞
	for prizeobjs in [ownprizesprize]
		for prizename,obj of prizeobjs
			prizes[prizename]=obj.name
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

# Complexのtype一致を確かめる
chkCmplType=(obj,cmpltype)->
	if obj.type=="Complex"
		obj.Complex_type==cmpltype || chkCmplType obj.Complex_main,cmpltype
	else
		false
# あるプレイヤーのある時点での役職を調べる
getTypeAtTime=(game,userid,day)->
	id=(pl=getpl(game,userid)).id
	ls=game.gamelogs.filter (x)->x.event=="transform" && x.id==id && x.day>day	# 変化履歴を調べる
	return ls[0]?.type ? pl.type

	

counterprize=
	# 呪殺
	cursekill:
		names:
			5:"スナイパー"
			15:"狐の天敵"
			30:"魔弾の狙撃手"
			50:"疾風怒濤の極大射程"
		func:(game,id)->
			# 呪殺を数える
			game.gamelogs.filter((x)->x.id==id && x.event=="cursekill").length
	# 初日黒
	divineblack2:
		names:
			3:"千里眼"
			10:"心眼"
		func:(game,id)->
			game.gamelogs.filter((x)->x.id==id && x.event=="divine" && x.flag in SS.shared.game.blacks).length
		
	# GJ判定
	GJ:
		names:
			5:"防御の達人"
			10:"キーパー"
			30:"精霊の守護者"
			50:"仁王"
			100:"守護神"
		func:(game,id)->
			game.gamelogs.filter((x)->x.id==id && x.event=="GJ").length
	# 恋人の勝利回数
	lovers_wincount:
		names:
			5:"両思い"
			10:"ラブラブカップル"
			20:"婚約"
			30:"結婚"
			50:"ベストカップル"
		func:(game,id)->
			pl=getpl game,id
			if pl.winner && chkCmplType pl,"Friend"
				1
			else
				0
	# 恋人の敗北回数
	lovers_losecount:
		names:
			10:"失恋"
			30:"離婚"
		func:(game,id)->
			pl=getpl game,id
			if pl.winner && chkCmplType pl,"Friend"
				1
			else
				0
	# 商品を受け取った回数
	getkits_merchant:
		names:
			10:"お得意様"
		func:(game,id)->
			game.gamelogs.filter((x)->x.target==id && x.event=="sendkit").length
	# 商品を人狼側に送った回数
	sendkits_to_wolves:
		names:
			10:"発注ミス"
		func:(game,id)->
			game.gamelogs.filter((x)->x.id==id && x.event=="sendkit" && getTypeAtTime(game,x.target,x.day)).length
	# コピーせずに終了
	nocopy:
		names:
			5:"優柔不断"
		func:(game,id)->
			if getpl(game,id).type=="Copier"
				1
			else
				0
	# 2日目昼に吊られた
	day2hanged:
		names:
			20:"怪しい人"
		func:(game,userid)->
			game.gamelogs.filter((x)->
				x.id==userid && x.event=="found" && x.flag=="punish" && x.day==2
			).length
	# 生き残った日数合計
###
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
# allcounterprizeはrealidが渡されるので注意
allcounterprize=
	# 総試合数
	allgamecount:
		names:
			5:"ビギナー"
			15:"ルーキー"
			30:"経験者"
			50:"エリート"
			75:"エース"
			100:"キャプテン"
			150:"ベテラン"
			200:"歴戦の絆"
			300:"百戦錬磨"
			400:"カリスマ"
			500:"アルティメット"
			600:"超電磁砲"
			750:"不敗神話"
			1000:"永遠の旅人"
			1250:"冥王"
			1500:"終末の巨人"
			2000:"レジェンド"
		func:(docs,realid)->docs.length
# docsから自分のみを抜き出したmesに対する処理
allplayersprize=
	# 総勝利数
	allwincount:
		names:
			5:"ポイントゲッター"
			10:"討つべし！"
			20:"期待の新星"
			30:"到達の証"
			50:"撃墜王"
			75:"勝利の絆"
			100:"武王"
			150:"スペシャリスト"
			200:"未来を紡ぎし者"
			300:"マスター"
			400:"絶対王者"
			500:"天下無双"
			750:"天衣無縫"
			1000:"全知全能"
			1500:"月の頭脳"
		func:(playerdocs,realid)->playerdocs.filter((x)->x.winner).length
# 称号一覧を元にして判定（数ではないので注意）
ownprizesprize=
	prizecount_100:
		name:"全てを超越せし者"
		# Booleanで返すこと
		func:(prizes,realid)->prizes.length>=100


prizes=makePrize()	# 賞の一覧 {"prize1":"賞1","prize2","賞2"} というようにIDと名前の辞書

# 内部用
exports.actions=
	checkPrize:(userid,cb)->
		#console.log "checking: #{userid}"
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
			# docsに自分のIDを追加する
			docs.forEach (game)->
				game.myid=getplreal(game,userid).id
			# カウント称号
			for prizename,obj of counterprize
				count=docs.sum (game)->obj.func game,game.myid
				for num in Object.keys(obj.names)
					# 昇順
					if num<=count
						result.push "#{prizename}_#{num}"
					else
						break
			# docごとカウント称号
			for prizename,obj of allcounterprize
				count=obj.func docs,userid
				for num in Object.keys(obj.names)
					# 昇順
					if num<=count
						result.push "#{prizename}_#{num}"
					else
						break
			# mesでカウントする称号
			for prizename,obj of allplayersprize
				count=obj.func mes,userid
				for num in Object.keys(obj.names)
					# 昇順
					if num<=count
						result.push "#{prizename}_#{num}"
					else
						break
			# prizesでカウントする称号
			for prizename,obj of ownprizesprize
				bool=obj.func result,userid
				if bool
					result.push prizename
			#console.log "#{userid} : #{JSON.stringify result}"
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

・単品系称号
"(称号名)" というIDをつける
###
