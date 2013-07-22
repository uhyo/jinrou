#ソケット関連
evs=[]
ons={}  #既にonになった
idn=1
# ソケット
exports.on=(mesname,channel=null,func)->
    ev=
        mesname:mesname
        func:func
        channel:channel
        id:idn++
    unless mesname of ons
        ons[mesname]=true

        ss.event.on mesname,(msg,channel_name)->
            evs.filter (x)->
                x.mesname==mesname && (!x.channel || x.channel==channel_name)
            .forEach (x)->
                x.func msg,channel_name
    evs.push ev
    console.log "on!",evs
    ev.id
        

exports.off=(id)->
    evs=evs.filter (x)->x.id!=id
    console.log "off!",evs
