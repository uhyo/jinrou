exports.showWindow=showWindow=(templatename,tmpl)->
	x=Math.max 50,Math.floor(Math.random()*100-200+document.documentElement.clientWidth/2)
	y=Math.max 50,Math.floor(Math.random()*100-200+document.documentElement.clientHeight/2)

	win=$("##{templatename}").tmpl(tmpl).hide().css({left:"#{x}px",top:"#{y}px",}).appendTo("body").fadeIn()#.draggable()
	$(".getfocus",win.get(0)).focus()
	win

#要素を含むWindowを消す
exports.closeWindow=closeWindow= (node)->
	w=$(node).closest(".window")
	w.hide "normal",-> w.remove()
	w.triggerHandler "close.window"
