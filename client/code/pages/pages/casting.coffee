exports.start=(rolename)->
    # 配役表 例)普通配役-普通1
    JinrouFront.loadI18n()
        .then((i18n)-> i18n.getI18nFor())
        .then((i18n)-> new Promise (resolve, reject)->
            # load additional resources required for this page.
            i18n.loadNamespaces 'page_casting', (err)->
                if err?
                    reject err
                else
                    resolve i18n)
        .then (i18n)->
            try
                rolename=decodeURIComponent rolename
            roleid = rolename.replace "-", "."
            func = Shared.game.getrulefunc roleid

            unless func?
                $("#roletitle").text i18n.t "page_casting:unknownCasting"
                return
            # set casting name and title.
            $("#rolename").text i18n.t "casting:castingName.#{roleid}"
            $("#roletitle").text i18n.t "casting:castingTitle.#{roleid}"

            jobs=[null] # 出現する役職の一覧

            the=$("#rolehead").get 0
            thr=the.insertRow 0
            th=document.createElement "th"
            th.textContent = i18n.t "page_casting:playerNumber"
            thr.appendChild th

            appendjob=(type)->
                th=document.createElement "th"
                a=document.createElement "a"
                a.href="/manual/job/#{type}"
                a.textContent=getjobname i18n, type
                th.appendChild a
                jobs.push type
                thr.appendChild th
            appendjob "Human"


            tb=$("#rolebody").get 0

            count=0 # 何個行をつくったか
            max=30  # 最大
            index=6 # 現在の人数
            while count<max
                obj=func index
                sum=0

                for key,value of obj
                    sum+=value
                    unless key in jobs  #新出の役職
                        appendjob key


                obj.Human=index-sum # 村人数算出
                if obj.Human<0  # 足りない
                    index++
                    continue

                tr=tb.insertRow -1
                td=tr.insertCell 0
                td.textContent=index    # 人数
                while tr.cells.length < jobs.length
                    tr.insertCell -1
                for key,value of obj
                    if value>0
                        td=tr.cells[jobs.indexOf key]
                        td?.textContent=value
                index++
                count++




exports.end=->

getjobname=(i18n, type)->
    i18n.t "roles:jobname.#{type}"

