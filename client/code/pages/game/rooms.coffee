exports.start=(query={})->
    mode = query.mode
    page = query.page || 0
    if page < 0
        page = 0
    getroom=Index.game.rooms.getroom
    gr=(rooms)->
        getroom mode,rooms
    ss.rpc "game.rooms.getRooms", mode,page,gr
    $("#pager").click (je)->
        t=je.target
        if t.name=="prev"
            page--
            if page<0 then page=0
            ss.rpc "game.rooms.getRooms", mode,page,gr
            Index.app.pushState location.pathname, {
                page: page
            }
        else if t.name=="next"
            page++
            ss.rpc "game.rooms.getRooms", mode,page,gr
            Index.app.pushState location.pathname, {
                page: page
            }

#mode: "old","log"など
exports.getroom=(mode,rooms)->
    tb=$("#roomlist").get(0)
    if rooms.error?
        Index.util.message "エラー","ルーム一覧を取得できませんでした。"
        return
    while tb.rows.length>0
        tb.deleteRow 0
        
    rooms.forEach (room)->
        tr=tb.insertRow -1
        if room.needpassword
            tr.classList.add "lock"
    
        #No.
        td=tr.insertCell -1
        a=document.createElement "a"
        a.href="/room/#{room.id}"
        a.textContent="#{room.name}(#{room.players.length})"
        td.appendChild a
        # 覆面フラグ
        if room.blind
            img=document.createElement "img"
            img.src="/images/blind.png"
            img.width=img.height=16
            img.alt="覆面"
            td.insertBefore img,td.firstChild
        # ロックフラグ
        if room.needpassword
            img=document.createElement "img"
            img.src=if mode=="old" then "/images/unlock.png" else "/images/lock.png"
            img.width=img.height=16
            img.alt="パスワード付き"
            td.insertBefore img,td.firstChild
        # GMあり村
        if room.gm
            img=document.createElement "img"
            img.src="/images/gm.png"
            img.width=img.height=16
            img.alt="GMあり"
            td.insertBefore img,td.firstChild
        
        #状態
        td=tr.insertCell -1
        td.textContent= switch room.mode
            when "waiting"
                "募集中"
            when "playing"
                "対戦中"
            when "end"
                "終了"
            else
                "不明"
        
        #owner
        td=tr.insertCell -1
        if room.owner?
            a=document.createElement "a"
            a.href="/user/#{room.owner.userid}"
            a.textContent=room.owner.name
            td.appendChild a
        else
            td.textContent="???"
        
        #ルール
        td=tr.insertCell -1
        td.textContent="#{room.number}人"
        
        #日時
        td=tr.insertCell -1
        if room.made?
            td.appendChild Index.util.timeFromDate new Date room.made
        
        #コメント
        td=tr.insertCell -1
        td.textContent=room.comment
            
