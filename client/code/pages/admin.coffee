tabs=
    blacklist:
        init:->
            unless blistpage?
                blistpage = 0
            initblisttable(blistpage)
            $("#newbanform").submit (je)->
                je.preventDefault()
                query=Index.util.formQuery je.target
                ss.rpc "admin.addBlacklist", query,->
                    initblisttable(blistpage)
            $("#blacklisttable").click (je)->
                target=je.target
                if target.dataset.banid
                    query=
                        id: target.dataset.banid
                    ss.rpc "admin.removeBlacklist", query,->
                        initblisttable(blistpage)
                else if target.dataset.setbanid
                    query=
                        id: target.dataset.setbanid
                    ss.rpc "admin.restoreBlacklist", query, ->
                        initblisttable(blistpage)
            $("#blistpager").click (je)->
                t=je.target
                if t.name=="prev"
                    blistpage--
                    if blistpage<0 then blistpage=0
                    initblisttable(blistpage)
                else if t.name=="next"
                    blistpage++
                    initblisttable(blistpage)
    grandalert:
        init:->
            $("#alertform").submit (je)->
                je.preventDefault()
                query=Index.util.formQuery je.target
                ss.rpc "admin.spreadGrandalert", query,(result)->
                    unless result?
                        # 成功
                        je.target.reset()
    dataexport:
        init:->
            $("#dataexportform").submit (je)->
                je.preventDefault()
                query=Index.util.formQuery je.target
                if query.command
                    ss.rpc "admin.doCommand", query,(result)->
                        if result.error?
                            Index.util.message "エラー",result.error
                            return
                        Index.util.message "出力",result.result
                else
                    ss.rpc "admin.dataExport", query,(result)->
                        if result.error?
                            Index.util.message "エラー",result.error
                            return
                        window.open result.file
    update:
        init:->
            $("#pullform").submit (je)->
                je.preventDefault()
                ss.rpc "admin.update",(result)->
                    if result.error
                        $("#pullresult").get(0).style.color="red"
                        $("#pullresult").text result.error
                    else
                        $("#pullresult").text result.result
                    Index.util.ask "管理ページ","人狼を終了しますか?",(result)->
                        if result
                            ss.rpc "admin.end",(result)->
    news:
        init:->
            initnewstable()
            $("#newnewsform").submit (je)->
                je.preventDefault()
                query=Index.util.formQuery je.target
                ss.rpc "admin.addNews", query,->
                    initnewstable()


exports.start=->
    Index.util.prompt "管理ページ","管理パスワードを入力してください",{type:"password"},(pass)->
        ss.rpc "admin.register", {password:pass},(err)->
            if err?
                Index.util.message "管理ページ",err
    $("#admin").click (je)->
        t=je.target
        if t.dataset.opener && to=tabs[t.dataset.opener]
            unless to.inited    # 初回
                to.init()
                to.inied=true
            e=$("##{t.dataset.opener}").get 0
            e.hidden=!e.hidden
        

    
exports.end=->

initblisttable=(page=0)->
    table=$("#blacklisttable").get 0
    ss.rpc "admin.getBlacklist", {page:page},(result)->
        if result.error?
            Index.util.message "管理ページ",result.error
            return
        $("span#page").text result.page+1
        $("span#total").text result.total
        $(table).empty()
        result.docs.forEach (doc)->
            row=table.insertRow -1
            cell=row.insertCell 0
            if Array.isArray doc.userid
                cell.textContent = doc.userid.join ", "
            else
                cell.textContent = doc.userid
            
            cell=row.insertCell 1
            if Array.isArray doc.ip
                cell.textContent = doc.ip.join ", "
            else
                cell.textContent = doc.ip
            
            cell=row.insertCell 2
            cell.textContent=(if doc.expires? then new Date(doc.expires).toLocaleString() else "無期限")
            
            cell=row.insertCell 3
            cell.textContent= doc.types?.join(", ")

            cell=row.insertCell 4
            cell.textContent= doc.reason

            cell=row.insertCell 5
            if doc.forgiveDate?
                cell.textContent = "解除済"
                input=document.createElement "input"
                input.type="button"
                input.dataset.setbanid=doc.id
                input.value="再設定"
                cell.appendChild input
            else if not doc.id?
                cell.textContent = "解除不可"
            else
                input=document.createElement "input"
                input.type="button"
                input.dataset.banid=doc.id
                input.value="解除"
                cell.appendChild input
    
initnewstable=->
    table=$("#newstable").get 0
    ss.rpc "admin.getNews", {num:10},(result)->
        if result.error?
            Index.util.message "管理ページ",result.error
            return
        $(table).empty()
        result.docs.forEach (doc)->
            row=table.insertRow -1
            cell=row.insertCell 0
            cell.textContent=doc._id

            cell=row.insertCell 1
            cell.textContent=doc.time.toLocaleString()
            
            cell=row.insertCell 2
            cell.textContent=doc.message
    
