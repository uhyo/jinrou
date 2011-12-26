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
				Werewolf:
					name:"人狼陣営"
					color:"#DD0000"
				Fox:
					name:"妖狐陣営"
					color:"#934293"
				Bat:
					name:"こうもり"
					color:"#000066"
				Neet:
					name:"ニート"
					color:"#CCCCCC"

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
				
			grp=(size=100)->
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
				gs.win[x]=results.filter((y)->y.team==x && y.winner==true).length
				gs.lose[x]=results.filter((y)->y.team==x && y.winner==false).length
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
			# 陣営別グラフ
			graph=grp()
			graph.hide()
			# 陣営ごとにまとめる
			gs=
				Human:0
				Werewolf:0
				Fox:0
				Bat:0
				Neet:0
			for x in teams
				gs[x]=results.filter((y)->y.team==x).length
			graph.setData gs,teamcolors
			graph.openAnimate 0.2
				
		
exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
	r=Object.create Object.getPrototypeOf obj1
	[obj1,obj2].forEach (x)->
		Object.getOwnPropertyNames(x).forEach (p)->
			r[p]=x[p]
	r
