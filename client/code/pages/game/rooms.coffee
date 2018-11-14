rooms_view = null
exports.start=(query={})->
    mode = query.mode
    page = query.page || 0
    noLinks = !!query.noLinks
    if page < 0
        page = 0

    pi18n = JinrouFront.loadI18n()
      .then((i18n)-> i18n.getI18nFor())
    papp = JinrouFront.loadRoomList()
    prooms = requestRooms mode, page

    Promise.all([pi18n, papp]).then ([i18n, app])->
        rooms_view = app.place {
          i18n: i18n
          node: $("#rooms-app").get 0
          pageNumber: 10
          listMode: mode ? ''
          noLinks: noLinks
          onPageMove: (dist)->
            page += dist
            if page < 0
              page = 0
            reqRpc()
            Index.app.pushState location.pathname, {
              page: page
            }
        }
        prooms.then (rooms)->
          getroom i18n, mode, rooms
          rooms_view.store.setRooms rooms
        getroom=Index.game.rooms.getroom

        reqRpc = ()->
            requestRooms(mode, page).then (rooms)->
              getroom i18n, mode, rooms
              rooms_view.store.setRooms rooms, page

        $("#pager").click (je)->
            t=je.target
            if t.name=="prev"
                page--
                if page<0 then page=0
                reqRpc()
                Index.app.pushState location.pathname, {
                    page: page
                }
            else if t.name=="next"
                page++
                reqRpc()
                Index.app.pushState location.pathname, {
                    page: page
                }
# Request rooms and return result as Promise.
requestRooms = (mode, page)->
  new Promise (resolve)->
    if mode == "my"
      ss.rpc "game.rooms.getMyRooms", page, resolve
    else
      ss.rpc "game.rooms.getRooms", mode, page, resolve

# mode: "old","log"など
# mode: "my"のときはi18nを渡す
exports.getroom=(i18n, mode, rooms)->
    tb=$("#roomlist").get(0)
    if rooms.error?
        console.error rooms.error
        Index.util.message "エラー","ルーム一覧を取得できませんでした。"
        return
    while tb.rows.length>0
        tb.deleteRow 0

    rooms.forEach (obj)->
        # TODO myのときとそれ以外で構造が違う
        room =
            if mode == "my"
                obj.room
            else
                obj

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

        if mode == "my"
            # 自分の戦績情報を入れる
            td = tr.insertCell -1
            job = Shared.game.getjobobj obj.job
            if job?
                sq = document.createElement "span"
                sq.style.color = job.color
                sq.textContent = "■"
                td.appendChild sq
                td.appendChild document.createTextNode i18n.t "roles:jobname.#{obj.job}"
            else if obj.job == "Helper"
                td.textContent = "ヘルパー"
            else if obj.job == "GameMaster"
                td.textContent = "ゲームマスター"
            else
                td.textContent = obj.job
            # 自分の名前を探してあれする
            for p in room.players
                if p.me
                    td.title = p.name
                    break

            td = tr.insertCell -1
            switch obj.subtype
                when "win"
                    span = document.createElement "span"
                    span.classList.add "rooms-td-win"
                    span.textContent = "勝ち"
                    td.appendChild span
                when "lose"
                    span = document.createElement "span"
                    span.classList.add "rooms-td-lose"
                    span.textContent = "負け"
                    td.appendChild span
                when "lose"
                    td.textContent = "引き分け"
        else
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
            a.classList.add "user-name"
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

exports.end = ->
  rooms_view?.unmount()
