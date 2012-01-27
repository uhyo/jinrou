#page module?

name_length_max=20

exports.start=(user)->
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
			# 陣営色
			teamcolors=merge SS.shared.game.jobinfo,{}

			results.forEach (x)->	# 陣営チェック
				for team of SS.shared.game.teams
					if x.type in SS.shared.game.teams[team]
						x.team=team
						break

				
			grp=(title,size=200)->
				# 新しいグラフ作成して追加まで
				h2=document.createElement "h2"
				h2.textContent=title
				$("#grapharea").append h2
				graph=SS.client.user.graph.circleGraph size
				p=document.createElement "p"
				p.appendChild graph.canvas
				$("#grapharea").append p
				graph
			
			# 勝率グラフ
			graph=grp "勝敗ごとの陣営"
			graph.hide()
			# 勝敗を陣営ごとに
			gs=
				win:{}
				lose:{}
			for x of SS.shared.game.teams
				gs.win[x]={}
				gs.lose[x]={}
			results.forEach (x)->
				console.log x.winner,x.team,gs
				if x.winner==true
					gs.win[x.team][x.type] ?= 0
					gs.win[x.team][x.type]++
				else if x.winner==false
					gs.lose[x.team][x.type] ?= 0
					gs.lose[x.team][x.type]++
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
			# 役職ごとの勝率
			graph=grp "役職ごとの勝敗"
			graph.hide()
			gs={}
			names=merge teamcolors,{}	#コピー
			for team of names
				gs[team]={}
				
				for type of names[team]
					continue if type in ["name","color"]
					names[team][type].win=
						name:"勝ち"
						color:"#FF0000"
					names[team][type].lose=
						name:"負け"
						color:"#0000FF"
					gs[team][type]=
						win:results.filter((x)->x.type==type && x.winner==true).length
						lose:results.filter((x)->x.type==type && x.winner==false).length
			console.log gs,names
			graph.setData gs,names
			graph.openAnimate 0.2
	# 称号
	unless user.prizenames?.length>0
		# 称号がない
		$("#prizearea").html "<p>獲得称号はありません。</p>"
	else
		ull=$("#prizes")
		user.prizenames.forEach (obj)->
			li=document.createElement "li"
			label=document.createElement "label"
			input=document.createElement "input"
			input.name="prizeselect"
			input.type="radio"
			input.value=obj.id
			if obj.id==user.nowprize
				input.checked=true
			label.appendChild input
			label.appendChild document.createTextNode obj.name
			li.appendChild label
			ull.append li
		$("#prizearea").submit (je)->
			je.preventDefault()
			que=SS.client.util.formQuery je.target
			SS.client.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
				if result
					query=
						password:result
						prize:que.prizeselect
					SS.server.user.usePrize query,(result)->
						if result?.error?
							SS.client.util.message "エラー",result.error
					
			
		
exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
	r=Object.create Object.getPrototypeOf obj1
	[obj1,obj2].forEach (x)->
		Object.getOwnPropertyNames(x).forEach (p)->
			r[p]=x[p]
	r
