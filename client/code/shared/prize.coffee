# 肩書きで、称号をつなげる接続語

exports.conjunctions=["の","を","が","は","で","と","な","に","し","い","す","だ","ぜ","ん","風","なる","たる","での","への","から","かつ","でも","する","した","オブ","にして","として","無き","☆","★","♡","♥","・","×","✝","ッ","！","的","デース","？"]
exports.prizes_composition=["prize","conjunction","prize"]

# 称号の数で
exports.getPrizesComposition=(number)->
    result=[]
    if number<25
        return ["prize","conjunction","prize"]
    else if number<40
        return ["prize","conjunction","prize","conjunction"]
    else if number<60
        return ["prize","conjunction","prize","conjunction","prize","conjunction"]
    else if number<100
        return ["conjunction","prize","conjunction","prize","conjunction","prize","conjunction"]
    else if number<150
        return ["prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    else if number<200
        return ["conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    else
        return ["prize","conjunction","prize","conjunction","prize","conjunction","conjunction","prize","conjunction","prize","conjunction"]
    
    result
