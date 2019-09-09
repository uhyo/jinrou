MAX_DICE_NUMBER = 10
MAX_DICE_SIZE = 100000000
MAX_COMMAND_NUM = 5

exports.processSpeakCommand = (comment)->
    command_count = 0
    supplement = []
    # ダイスコマンドの処理
    commandr = /!(\d+)[dD](\d+)/g
    while res = commandr.exec comment
        if command_count >= MAX_COMMAND_NUM
            return {
                error: "tooManyCommands"
            }
        command_count++
        [_, dicenum, dicesize] = res
        dicenum = parseInt(dicenum, 10)
        dicesize = parseInt(dicesize, 10)
        unless 0 < dicenum <= MAX_DICE_NUMBER && 0 < dicesize < MAX_DICE_SIZE
            # 大きすぎる
            supplement.push {
                type: "dice"
                result: null
            }
        else
            result = for i in [0...dicenum]
                1 + Math.floor Math.random() * dicesize
            supplement.push {
                type: "dice"
                result: result
            }
    return supplement
