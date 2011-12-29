#page module?

name_length_max=20

exports.start=->
	$("section.profile p.edit").click (je)->
		t=je.target
		inp=document.createElement "input"
		inp.value=t.textContent
		inp.name=t.dataset.pname
		inp.type=t.dataset.type
		inp.maxlength=t.dataset.maxlength
		inp.required=true if t.dataset.required
		np=document.createElement "p"
		np.appendChild inp
		t.parentNode?.replaceChild np,t
		inp.focus()
		
	$("#changeprofile").submit (je)->
		je.preventDefault()
		q=SS.client.util.formQuery je.target
		q.userid=$("p.userid").get(0).textContent
		console.log q
		SS.client.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
			if result
				q.password=result
				console.log q
				SS.server.user.changeProfile q,(result)->
					console.log result
					if result.error?
						SS.client.util.message "エラー",result.error
					else
						SS.client.app.page "templates-user-profile",result,SS.client.user.profile
	$("#morescore").submit (je)->
		je.target.elements["submit"].disabled=true
		je.preventDefault()
		SS.server.user.analyzeScore (obj)->
			if obj.error?
				SS.client.util.message "エラー",obj.error
			results=obj.results
			console.log results
			teams=["Human","Werewolf","Fox","Bat","Neet"]	# 陣営一覧
			# 陣営色
			teamcolors=
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
					MadWolf:
						name:"狂人狼"
						color:"#847430"
					Spy2:
						name:"スパイⅡ"
						color:"#d3b959"
					
					
				Fox:
					name:"妖狐陣営"
					color:"#934293"
					Fox:
						name:"妖狐"
						color:"#934293"
					TinyFox:
						name:"子狐"
						color:"#dd81f0"
						
					
				Bat:
					name:"こうもり"
					color:"#000066"
					Bat:
						name:"こうもり"
						color:"#000066"
					
				Neet:
					name:"ニート"
					color:"#aaaaaa"
					Neet:
						name:"ニート"
						color:"#aaaaaa"

			results.forEach (x)->	# 陣営チェック
				x.team=
					if x.type in SS.shared.game.wolves
						"Werewolf"					
					else if x.type in SS.shared.game.foxes
						"Fox"
					else if x.type=="Bat"
						"Bat"
					else if x.type=="Neet"
						"Neet"
					else
						"Human"
				
			grp=(size=200)->
				# 新しいグラフ作成して追加まで
				graph=SS.client.user.graph.circleGraph size
				p=document.createElement "p"
				p.appendChild graph.canvas
				$("#grapharea").append p
				graph
			
			# 勝率グラフ
			graph=grp()
			graph.hide()
			# 勝敗を陣営ごとに
			gs=
				win:{}
				lose:{}
			for x in teams
				gs.win[x]={}
				gs.lose[x]={}
			results.forEach (x)->
				if x.winner==true
					gs.win[x.team][x.type] ?= 0
					gs.win[x.team][x.type]++
				else if x.winner==false
					gs.lose[x.team][x.type] ?= 0
					gs.lose[x.team][x.type]++
			console.log merge {
					name:"勝ち"
					color:"#FF0000"
				},teamcolors
			graph.setData gs,{
				win:merge {
					name:"勝ち"
					color:"#FF0000"
				},teamcolors
				lose:merge {
					name:"負け"
					color:"#0000FF"
				},teamcolors
			}
			graph.openAnimate 0.2
				
		
exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
	r=Object.create Object.getPrototypeOf obj1
	[obj1,obj2].forEach (x)->
		Object.getOwnPropertyNames(x).forEach (p)->
			r[p]=x[p]
	r
