exports.start=->
	# 役職数
	$("#number_of_jobs").text SS.shared.game.jobs.length
	
	# 役職一覧ページ
	j=$("#joblist_main")
	if j.get 0
		for job in SS.shared.game.jobs
			j.append $("#templates-jobs-#{job}").tmpl()
				
		

			

exports.end=->

