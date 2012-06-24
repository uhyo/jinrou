#entry!

# global ss
window.ss=require 'socketstream'

ss.server.on 'ready',->
	# 全てのやつ
	window.Index=require '/index'
	window.Shared=
		game:require '/game'
		prize:require '/prize'
	# 最初
	require('/app').init()

