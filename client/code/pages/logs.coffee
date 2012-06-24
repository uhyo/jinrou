exports.start=->
	page=0
	query=null
	getroom=Index.game.rooms.getroom
	#ss.rpc "game.rooms.getRooms", mode,page,getroom

	# ルールの設定
	setjobrule=(rulearr,names,parent)->
		for obj in rulearr
			# name,title, ruleをもつ
			if obj.rule instanceof Array
				# さらに子
				optgroup=document.createElement "optgroup"
				optgroup.label=obj.name
				parent.appendChild optgroup
				setjobrule obj.rule,names.concat([obj.name]),optgroup
			else
				# option
				option=document.createElement "option"
				option.textContent=obj.name
				option.value=names.concat([obj.name]).join "."
				option.title=obj.title
				parent.appendChild option
	setjobrule Shared.game.jobrules.concat([
		name:"特殊ルール"
		rule:[
			{
				name:"自由配役"
				title:"配役を自由に設定できます。"
				rule:null
			}
			{
				name:"闇鍋"
				title:"配役がランダムに設定されます。"
				rule:null
			}
			{
				name:"一部闇鍋"
				title:"一部の配役を固定して残りをランダムにします。"
				rule:null
			}
		]
	]),[],$("#rulebox").get 0
	$("#pager").click (je)->
		return unless query?
		t=je.target
		if t.name=="prev"
			page--
			if page<0 then page=0
			ss.rpc "game.rooms.find", query,page,getroom
		else if t.name=="next"
			page++
			ss.rpc "game.rooms.find", query,page,getroom
		
	$("#logsform").change (je)->
		# disable/able
		t=je.target
		if result=t.name.match /^(.+)_on$/
			t.form.elements[result[1]].disabled= !t.checked
	$("#logsform").submit (je)->
		form=je.target
		je.preventDefault()
		query={}
		# 数値
		for x in ["min_number","max_number","min_day","max_day"]
			unless form.elements[x].disabled
				query[x]=parseInt form.elements[x].value
		for x in ["result_team","rule"]
			unless form.elements[x].disabled
				query[x]=form.elements[x].value
			
		
		ss.rpc "game.rooms.find", query,page,(rooms)->
			getroom rooms
		
			

exports.end=->
