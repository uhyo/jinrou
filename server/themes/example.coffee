module.exports=
    name:"東方Project"
    opening:"異変だ！"
    vote:""
    sunrise:""
    sunset:""
    icon:""
    background_color:"black"
    color:"rgb(255,0,166)"
    skins:
        hakurei_reimu:
            # link
            avatar:"https://img.example.com/some_character.jpg"
            # name is necessary
            name:"博麗 霊夢"
            # prize
            prize:["八百万の代弁者","博麗神社の巫女さん","空飛ぶ不思議な巫女"]
        kirisame_marisa:
            # Array of link
            avatar:["https://img.example.com/some_other_character_1.jpg","https://img.example.com/some_other_character_2.jpg"]
            name:"霧雨 魔理沙"
            # prize could be empty
            prize:""
    # to let players know who they are
    skin_tip:"あなたは"
    lockable:false
    isAvailable:->
        # if want to be a time limited theme
        # return false
        return true
