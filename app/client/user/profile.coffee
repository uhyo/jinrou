#page module?

name_length_max=20

exports.start=(user)->
	if user?.icon?
		$("#myicon").attr "src",user.icon
	
	$("section.profile p.edit").click (je)->
		transforminput je.target
	transforminput=(t)->
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
		SS.client.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
			if result
				q.password=result
				SS.server.user.changeProfile q,(result)->
					if result.error?
						SS.client.util.message "エラー",result.error
					else
						SS.client.app.page "templates-user-profile",result,SS.client.user.profile,result
	.get(0).elements["changepasswordbutton"].addEventListener "click",((e)->
		$("#changepassword").get(0).hidden=false
		$("#changepassword").submit (je)->
			je.preventDefault()
			SS.server.user.changePassword SS.client.util.formQuery(je.target),(result)->
				if result?.error?
					SS.client.util.message "エラー",result.error
				else
					$("#changepassword").get(0).hidden=true
					SS.client.app.page "templates-user-profile",result,SS.client.user.profile
					
	),false
	$("#changeprofile").get(0).elements["twittericonbutton"].addEventListener "click",((e)->
		SS.client.util.prompt "アイコン","twitterIDを入力して下さい",{},(id)->
			return unless id
			transforminput $(e.target.form).find("p[data-pname=\"icon\"]").get(0)
			e.target.form.elements["icon"].value="http://api.twitter.com/1/users/profile_image/#{id}"
	),false
	
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
			graph.setData gs,names
			graph.openAnimate 0.2
	# 称号
	unless user.prizenames?.length>0
		# 称号がない
		$("#prizearea").html "<p>獲得称号はありません。</p>"
	else
		ull=$("#prizes")
		prizedictionary={}	# 称号のidと名前対応
		user.prizenames.forEach (obj)->
			li=document.createElement "li"
			li.textContent=obj.name
			li.dataset.id=obj.id
			li.classList.add "prizetip"
			li.draggable=true
			ull.append li
			prizedictionary[obj.id]=obj.name
		ull=$("#conjunctions")
		for te in SS.shared.prize.conjunctions
			li=document.createElement "li"
			li.textContent=te
			li.classList.add "conjtip"
			li.draggable=true
			ull.append li
		# 消すやつを追加
		li=document.createElement "li"
		li.textContent="消す"
		li.classList.add "deleter"
		li.draggable=true
		ull.append li
		
		# 編集部分
		ull=$("#prizeedit")
		unless user.nowprize?	# 無い場合はデフォルト
			for te in SS.shared.prize.prizes_composition
				li=document.createElement "li"
				li.classList.add (if te=="prize" then "prizetip" else "conjtip")
				ull.append li
		else
			for obj in user.nowprize
				li=document.createElement "li"
				if obj.type=="prize"
					li.classList.add "prizetip"
					li.dataset.id=obj.value
					li.textContent=prizedictionary[obj.value] ? ""
				else
					li.classList.add "conjtip"
					li.textContent=obj.value
				ull.append li
		$("#prizeedit li").each ->
			@dropzone="copy"
			
		# dragstart
		dragstart=(e)->
			e.dataTransfer.setData 'Text',JSON.stringify {id:e.target.dataset.id, value:e.target.textContent,deleter:e.target.classList.contains "deleter"}
		$("#pdragzone").get(0).addEventListener "dragstart",dragstart,false
		ull.get(0).addEventListener "dragover",((e)->
			if e.target.tagName=="LI"
				e.preventDefault()	# ドロップできる
		),false
		ull.get(0).addEventListener "drop",((e)->
			t=e.target
			if t.tagName=="LI"
				e.preventDefault()
				obj=JSON.parse e.dataTransfer.getData("Text")
				if obj.deleter	#消す
					delete t.dataset.id
					t.textContent=""
					return
				if obj.id	# prizeだ
					if t.classList.contains "prizetip"
						t.dataset.id=obj.id
						t.textContent=obj.value
				else
					if t.classList.contains "conjtip"
						t.textContent=obj.value
		),false
		
			
		$("#prizearea").submit (je)->
			je.preventDefault()
			que=SS.client.util.formQuery je.target
			SS.client.util.prompt "プロフィール","パスワードを入力して下さい",{type:"password"},(result)->
				if result
					query=
						password:result
					prize=[]
					$("#prizeedit li").each ->
						if @classList.contains "prizetip"
							# prizeだ
							prize.push {
								type:"prize"
								value:@dataset.id ? null
							}
						else
							prize.push {
								type:"conjunction"
								value:@textContent
							}
						null
					query.prize=prize
					
					SS.server.user.usePrize query,(result)->
						if result?.error?
							SS.client.util.message "エラー",result.error
	
	SS.client.game.rooms.start()	# ルーム一覧を表示してもらう	
exports.end=->

#Object2つをマージ（obj1ベース）
merge=(obj1,obj2)->
	r=Object.create Object.getPrototypeOf obj1
	[obj1,obj2].forEach (x)->
		Object.getOwnPropertyNames(x).forEach (p)->
			r[p]=x[p]
	r
