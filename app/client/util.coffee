exports.showWindow=showWindow=(templatename,tmpl)->
	x=Math.max 50,Math.floor(Math.random()*100-200+document.documentElement.clientWidth/2)
	y=Math.max 50,Math.floor(Math.random()*100-200+document.documentElement.clientHeight/2)

	win=$("##{templatename}").tmpl(tmpl).hide().css({left:"#{x}px",top:"#{y}px",}).appendTo("body").fadeIn()#.draggable()
	$(".getfocus",win.get(0)).focus()
	win
#編集域を返す
exports.blankWindow=->
	win=showWindow "templates-util-blank"
	div=document.createElement "div"
	$("form[name='okform']",win).before div
	win.submit (je)-> je.preventDefault()
	win.click (je)->
		t=je.target
		if t.name=="ok"
			closeWindow t
	$(div)
	

#要素を含むWindowを消す
exports.closeWindow=closeWindow= (node)->
	w=$(node).closest(".window")
	w.hide "normal",-> w.remove()
	w.triggerHandler "close.window"
	
exports.formQuery=(form)->
	q={}
	el=form.elements
	for e in el
		if !e.disabled && e.name
			if (tag=e.tagName.toLowerCase())=="input"
				if e.type in ["radio","checkbox"]
					if e.checked
						q[e.name]=e.value
				else if e.type!="submit" && e.type!="reset" && e.type!="button"
					q[e.name]=e.value
			else if tag=="select"
				q[e.name]=e.value
			else if tag=="output"
				q[e.name]=e.value
	q
#true,false
exports.ask=(title,message,cb)->
	win = showWindow "templates-util-ask",{title:title,message:message}
	win.submit (je)-> je.preventDefault()
	win.click (je)->
		t=je.target
		if t.name=="yes"
			cb true
			closeWindow t
		else if t.name=="no"
			cb false
			closeWindow t
#String / null
exports.prompt=(title,message,opt,cb)->
	win = showWindow "templates-util-prompt",{title:title,message:message}
	inp=win.find("input.prompt").get(0)
	for opv of opt
		inp[opv]=opt[opv]
	win.submit (je)-> je.preventDefault()
	win.click (je)->
		t=je.target
		if t.name=="ok"
			cb? inp.value
			closeWindow t
		else if t.name=="cancel"
			cb? null
			closeWindow t

#arr: [{name:"aaa",value:"foo"}, ...]
exports.selectprompt=(title,message,arr,cb)->
	win = showWindow "templates-util-selectprompt",{title:title,message:message}
	sel=win.find("select.prompt").get(0)
	for obj in arr
		opt=document.createElement "option"
		opt.textContent=obj.name
		opt.value=obj.value
		sel.add opt
	win.submit (je)-> je.preventDefault()
	win.click (je)->
		t=je.target
		if t.name=="ok"
			cb? sel.value
			closeWindow t
		else if t.name=="cancel"
			cb? null
			closeWindow t
		


exports.message=(title,message,cb)->
	win = showWindow "templates-util-wmessage",{title:title,message:message}
	win.submit (je)-> je.preventDefault()
	win.click (je)->
		t=je.target
		if t.name=="ok"
			cb? true
			closeWindow t
# Dateをtime要素に
exports.timeFromDate=(date)->
	zero2=(num)->
		"00#{num}".slice -2	# 0埋め
	dat="#{date.getFullYear()}-#{zero2(date.getMonth()+1)}-#{zero2(date.getDate())}"
	tim="#{zero2(date.getHours())}:#{zero2(date.getMinutes())}:#{zero2(date.getSeconds())}"
	time=document.createElement "time"
	time.datetime="#{dat}T#{tim}+09:00"
	time.textContent="#{dat} #{tim}"
	time
