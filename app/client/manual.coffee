exports.start=->
	# 役職数
	$("#number_of_jobs").text SS.shared.game.jobs.length
	
	# 役職一覧ページ
	if location.pathname=="/manual/joblist"
		j=$("#joblist_main")
		for job in SS.shared.game.jobs
			j.append $("#templates-jobs-#{job}").tmpl()
				
		

			

exports.end=->

