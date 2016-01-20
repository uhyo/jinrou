# 高負荷をかけるクライアントを遮断する
#

MEMORY_MAX = 20 # 直近何件のリクエストを記録するか
BARRIER_NUM= 10 # 時間中に何件連続したら弾くか

BARRIER_TIME=500   #計測するms

database = []
last_time = Date.now()

exports.wall = ()=>
    return (req,res,next)=>
        id=req.socketId
        now=Date.now()
        sa = now-last_time
        last_time=now
        if sa>=BARRIER_TIME
            # 時間経過しているから問題ない
            database=[]
            next()
        else
            database.push id
            if database.length>MEMORY_MAX
                database.shift()
            # 自分がなんぼいるか数える
            count=0
            flg=false
            for d in database
                if d==id
                    if ++count >= BARRIER_NUM
                        flg=true
                        break
            if flg==true
                # 閾値を超えてアクセスした
                console.log "client #{id} filtered by the firewall"
                res null
            else
                # ファイヤウォール突破
                next()
            

