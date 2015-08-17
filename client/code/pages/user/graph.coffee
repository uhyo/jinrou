# graph module
class Graph
    margin:10
    constructor:(@size)->
        @canvas=document.createElement "canvas"
        @canvas.height=@size+@margin*2
        @canvas.width=@size+@margin*2
        @ctx=@canvas.getContext '2d'
        @canvas.style.float="left"
        @canvas.style.clear="both"
        
        @data=null
    setData:(@data)->

class CircleGraph extends Graph
    constructor:->
        super
        @circ=1 #0～1で円の完成度
        @table=null
    hide:->@circ=0
    setData:(@data,@names)->    #names: 値の名字と実際のアレの対応
        #@names={ Human:{name:"村人",color:"#FF0000"}...}
        chk=(d,vals)->  # 合計算出 valsも一緒に作る
            unless typeof d=="object"
                return d
            su=0
            for name,value of d
                if typeof value=="object"
                    # 入れ子
                    arr=[]
                    arr.name=name
                    vals?.push arr
                    su+=chk value,arr
                else
                    vals?.push name
                    su+=value
                    
            su
                
        @vals=[]
        @sum=chk @data,@vals
        #大きい順にsort
        @depth=1    # 深度 最高いくつの深さがあるか
        sortv=(vals,data,dp=1)=>    #dp: 現在の深度
            @depth=Math.max @depth,dp
            vals.forEach (x)->
                if x instanceof Array
                    sortv x,data[x.name],dp+1
            vals.sort (a,b)->(chk data[if b instanceof Array then b.name else b])-(chk data[if a instanceof Array then a.name else a])
        sortv @vals,@data
        #table作成
        if @table?.parentNode
            @table.parentNode.removeChild @table
        @table=document.createElement "table"
        datatable= (data,vals,names,dp=0)=>
            for name in vals
                _name=name
                if typeof name=="object" then _name=name.name
                thissum=chk data[_name]
                continue unless thissum
                tr=@table.insertRow -1
                td=tr.insertCell -1
                td.style.color=names[_name].color ? "#cccccc"
                i=0
                spaces= ("　" while i++<dp).join ""
                td.textContent="#{spaces}■"
                td=tr.insertCell -1
                if typeof data[_name]=="object"
                    # 子がある
                    td.textContent="#{names[_name].name} #{thissum}(#{(thissum/@sum*100).toPrecision(2)}%)"
                    datatable data[_name],name,names[_name],dp+1
                else
                    td.textContent="#{names[_name].name} #{data[_name]}(#{(data[_name]/@sum*100).toPrecision(2)}%)"
        datatable @data,@vals,@names
        if @canvas.parentNode
            @canvas.parentNode.insertBefore @table,@canvas.nextSibling
        @draw()
    openAnimate:(sec,step=0.02)->
        # sec[s]かけてオープン
        step=Math.max step,sec/60   #60fps以上は出したくない
        @circ=0
        ss= =>
            @circ+=step
            if @circ>1 then @circ=1
            @draw()
            if @circ<1
                setTimeout ss,sec/step
        ss()
    draw:->
        ctx=@ctx
        ctx.save()
        ctx.translate @margin,@margin
        tx=ty=r=@size/2 # グラフ中心,半径
        dx=@size+@margin*2  # 説明部分左端
        sum=0   #ここまでの角度合計
        startangle=-Math.PI/2   #始点は上
        onepart=(data,vals,names,start,dp=1)=>
            #start: 始点の角度
            for name in vals
                _name=name
                # 順番に描画
                if typeof name=="object"
                    _name=name.name #valsのオブジェクトにはname
                rad=Math.PI*2*@getsum(data[_name])/@sum*@circ
            
                ctx.beginPath()
                # 外側の弧
                ctx.arc tx,ty,r*dp/@depth,start+startangle,start+rad+startangle,false
                # 内側の弧
                ctx.arc tx,ty,r*(dp-1)/@depth,start+rad+startangle,start+startangle,true
                ctx.closePath()
                ctx.fillStyle=names[_name].color ? "#cccccc"
                ctx.fill()
                if typeof name=="object"
                    # 子供たち
                    onepart data[_name],name,names[_name],start,dp+1
                start+=rad  #描画した
            
                
        onepart @data,@vals,@names,0

        ctx.restore()
    getsum:(data)->
        unless typeof data=="object"
            return data
        sum=0
        for name,value of data
            sum+=@getsum value
        sum
        
            
        
        
            

exports.circleGraph=(size)->new CircleGraph size
