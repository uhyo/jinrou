tabs=
    blacklist:
        init:->
            initblisttable()
            $("#newbanform").submit (je)->
                je.preventDefault()
                query=Index.util.formQuery je.target
                ss.rpc "admin.addBlacklist", query,->
                    inittable()
            $("#blacklisttable").click (je)->
                target=je.target
                if target.dataset.userid
                    query=
                        userid:target.dataset.userid
                    ss.rpc "admin.removeBlacklist", query,->
                        inittable()
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
                            Index.util.message "错误",result.error
                            return
                        Index.util.message "报告",result.result
                else
                    ss.rpc "admin.dataExport", query,(result)->
                        if result.error?
                            Index.util.message "错误",result.error
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
                    Index.util.ask "管理界面","要停止人狼服务器吗?",(result)->
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
    Index.util.prompt "管理界面","请输入管理密码",{type:"password"},(pass)->
        ss.rpc "admin.register", {password:pass},(err)->
            if err?
                Index.util.message "管理界面",err
    $("#admin").click (je)->
        t=je.target
        if t.dataset.opener && to=tabs[t.dataset.opener]
            unless to.inited    # 初回
                to.init()
                to.inied=true
            e=$("##{t.dataset.opener}").get 0
            e.hidden=!e.hidden
        

    
exports.end=->

initblisttable=->
    table=$("#blacklisttable").get 0
    ss.rpc "admin.getBlacklist", {},(result)->
        if result.error?
            Index.util.message "管理界面",result.error
            return
        $(table).empty()
        result.docs.forEach (doc)->
            row=table.insertRow -1
            cell=row.insertCell 0
            a=document.createElement "a"
            a.href="/user/#{doc.userid}"
            a.textContent=doc.userid
            cell.appendChild a
            
            cell=row.insertCell 1
            cell.textContent=doc.ip
            
            cell=row.insertCell 2
            cell.textContent=doc.expires?.toLocaleString() ? "无期限"
            
            cell=row.insertCell 3
            input=document.createElement "input"
            input.type="button"
            input.dataset.userid=doc.userid
            input.value="解除"
            cell.appendChild input
    
initnewstable=->
    table=$("#newstable").get 0
    ss.rpc "admin.getNews", {num:10},(result)->
        if result.error?
            Index.util.message "管理界面",result.error
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
    
