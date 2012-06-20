#entry!

# global ss
window.ss=require 'socketstream'

ss.server.on 'ready',->
	# 最初
	require '/app'

