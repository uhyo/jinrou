exports.start=->
	# 役職数
	$("#number_of_jobs").text Shared.game.jobs.length
	
	# 役職一览ページ
	j=$("#joblist_main")
	if j.get 0
		for job in Shared.game.jobs
			j.append $ JT["jobs-#{job}"]()
	# 一番上にスクロール
	window.scrollTo 0,0
				
		

			

exports.end=->

