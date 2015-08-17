exports.start=->
	# 配役種類一览
	console.log "hi"
	dl=$("#castings")
	jobrules=Shared.game.jobrules
	app dl,jobrules

exports.end=->

app=(dl,arr,prefixes=[])->
	# dlにarr以下のものを追加
	for obj in arr
		rule=obj.rule
		if Array.isArray rule
			# 子がある
			dt=$("<dt>").text(obj.name).appendTo dl
			dd=$("<dd>").appendTo dl
			dll=$("<dl>").appendTo dd
			app dll,obj.rule,prefixes.concat(obj.name)
		else
			# 详细
			dt=$("<dt>").appendTo dl
			a=$("<a href='/manual/casting/#{prefixes.concat(obj.name).join('-')}'>").text(obj.name).appendTo dt
			dd=$("<dd>").text(obj.title).appendTo dl
