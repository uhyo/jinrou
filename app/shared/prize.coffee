# 肩書きで、称号をつなげる接続語

exports.conjunctions=["の","を","が","は","で","と","な","に","し","い","風","なる","たる","での","への","から","かつ","でも","する","した","オブ","にして","として","無き","的な","☆","★","♡","♥","・","×"]
exports.prizes_composition=["prize","conjunction","prize"]

# 称号の数で
exports.getPrizesComposition=(number)->
	result=[]
	if number>=30
		result.push "conjunction"	# 30個で最初に接続
	result.push "prize"	# 称号1
	result.push "conjunction" # 接続
	if number>=50
		result.push "prize"	# 50個で称号3
	if number>=40
		result.push "conjunction"	#40個で追加の接続
	result.push "prize"	# 称号2
	if number>=20
		result.push "conjunction"	# 20個で最後に接続
	
	result
