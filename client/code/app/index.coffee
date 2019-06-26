# クライアント側のページを集約する
module.exports=
    user:
        profile:require '/user/profile'
        view:require '/user/view'
        graph:require '/user/graph'
        mylog:require '/user/mylog'
        settings:require '/user/settings'
        prize:require '/user/prize'
    game:
        rooms:require '/game/rooms'
        newroom:require '/game/newroom'
        game:require '/game/game'
    lobby:require '/lobby'
    manual:require '/manual'
    admin:require '/admin'
    logs:require '/logs'
    reset:require '/reset'
    tutorial:
        game: require '/tutorial/game'
    pages:
        casting:require '/pages/casting'
        castlist:require '/pages/castlist'
    top:require '/top'
    # ちょっと違うけど
    app:require '/app'
    util:require '/util'
    socket:require '/socket'





