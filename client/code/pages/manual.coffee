exports.start=->
	# 役職数
	$("#number_of_jobs").text Shared.game.jobs.length

	# 役職一覧ページ
	j=$("#joblist_main")
	if j.get 0
        # list up all jobs.
        Promise.all([
            JinrouFront.loadI18n().then((i18n)-> i18n.getI18nFor()),
            JinrouFront.loadManual().then((manual)->
                # preload manual data.
                manual.loadRoleManual('Human').then(()->
                    Promise.all(Shared.game.jobs.map((job)->
                        manual.loadRoleManual(job)
                            .then((data)->
                                [job, data]))))
                )
        ])
            .then ([i18n, roles])->
                for [roleid, renderer] in roles
                    sec = $ "<section class='jobmanual'>"
                    title = $("<h1>").text i18n.t "roles:jobname.#{roleid}"
                    sec.append title
                    sec.append $(renderer())
                    j.append sec
	# 一番上にスクロール
	window.scrollTo 0,0





exports.end=->

