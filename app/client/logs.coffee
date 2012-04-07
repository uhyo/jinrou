exports.start=->
	page=0
	query=null
	getroom=SS.client.game.rooms.getroom
	#SS.server.game.rooms.getRooms mode,page,getroom
	$("#pager").click (je)->
		return unless query?
		t=je.target
		if t.name=="prev"
			page--
			if page<0 then page=0
			SS.server.game.rooms.find query,page,getroom
		else if t.name=="next"
			page++
			SS.server.game.rooms.find query,page,getroom
		
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
		unless form.elements["result_team"].disabled
			query.result_team=form.elements["result_team"].value
			
		
		SS.server.game.rooms.find query,page,(rooms)->
			console.log rooms
			getroom rooms
		
			

exports.end=->
