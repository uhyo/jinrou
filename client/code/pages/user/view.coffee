exports.start=(userid)->
    ss.rpc "user.userData", userid,null,(obj)->
        unless obj?
            Index.util.message "エラー","そのユーザーは存在しません"
            return
        user = obj.user
        $("#uname").text user.name
        $("#userid").text userid
        $("#usercomment").text user.comment
        # 戦績
        usersummary = obj.usersummary
        if usersummary?
            if usersummary.open

                $("#usersummary").append """
                <p>最近#{usersummary.days}日間の戦績：</p>
                <p>対戦数<b>#{usersummary.game_total}</b>，勝利数<b>#{usersummary.win}</b>，敗北数<b>#{usersummary.lose}</b></p>
                <p>GM数：<b>#{usersummary.gm}</b>，ヘルパー数<b>#{usersummary.helper}</b></p>
                <p>突然死数：<b>#{usersummary.gone}</b> #{if usersummary.game_total > 0 then "(#{(usersummary.gone / usersummary.game_total * 100).toFixed(1)}%)" else ""}</p>
                """
            else
                $("#usersummary").append """
                <p>最近#{usersummary.days}日間の戦績は非公開です。（最近#{usersummary.days}日間の突然死率：#{(if usersummary.game_total > 0 then usersummary.gone / usersummary.game_total * 100 else 0).toFixed(1)}%）</p>
                    """
        userlog = obj.userlog
        if userlog?
            $("#usersummary").append """
                <p>全期間の戦績：</p>
                <p>対戦数<b>#{userlog.game}</b>，勝利数<b>#{userlog.win}</b>，敗北数<b>#{userlog.lose}</b></p>
                """
        else
            $("#usersummary").append """
                <p>全期間の戦績は非公開です。</p>
                """


exports.end=->
