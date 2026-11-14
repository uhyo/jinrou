crypto=require 'crypto'

#ユーザー管理の何か
user=require './rpc/user.coffee'
#params: params.userid, params.password
exports.authenticate = (params,cb) ->
    M.users.findOne {userid:params.userid}, (err,doc)->
        unless doc?
            cb {success:false}
            return
        unless check params.password, doc.password, doc.salt
            # パスワードが違う
            cb {success:false}
            return
        unless doc.salt?
            # パスワードが古いので新しいハッシュで保存
            salt = gensalt()
            ha = crpassword params.password, salt
            M.users.update {userid:params.userid}, {
                $set: {
                    password: ha,
                    salt: salt,
                },
            }, {safe:true}, (err, count)->
                if err?
                    cb {success:false}
                    return
                # 成功
                delete doc.password
                doc.success=true
                cb doc
        else
            delete doc.password
            delete doc.salt
            doc.success=true
            cb doc

# パスワードが一致するか確かめる
exports.check = check = (raw, hash, salt)->
    return false unless typeof raw == 'string' && typeof hash == 'string'
    expected = if salt? then crpassword(raw, salt) else crpassword_old(raw)
    a = Buffer.from expected
    b = Buffer.from hash
    # 長さが違う場合もタイミング差を抑えるため、ダミー比較して false
    return false unless a.length == b.length && a.length > 0
    return crypto.timingSafeEqual a, b

# saltを生成
exports.gensalt = gensalt = ()->
    return crypto.randomBytes(32).toString 'hex'
# パスワードハッシュ化
exports.crpassword = crpassword = (raw, salt)->
    return "" unless raw && salt
    sha256 = crypto.createHash "sha256"
    sha256.update "#{salt}#{raw}"
    return sha256.digest 'hex'

# 古いパスワードハッシュ
crpassword_old = (raw)->
    sha256=crypto.createHash "sha256"
    md5=crypto.createHash "md5"
    md5.update raw  # md5でハッシュ化
    sha256.update raw+md5.digest 'hex'  # sha256でさらにハッシュ化
    sha256.digest 'hex' # 結果を返す

# ---- 自動ログイン用トークン ------------------------------------------------
TOKEN_EXPIRE_DAYS_DEFAULT = 3
# 同一 userid で同時に有効なトークンの上限
MAX_TOKENS_PER_USER = 3
getTokenExpireMs = ->
    days = Config.login?.tokenExpireDays
    unless typeof days == 'number' and days > 0
        days = TOKEN_EXPIRE_DAYS_DEFAULT
    Math.floor days * 24 * 60 * 60 * 1000

tokenHash = (token)->
    crypto.createHash('sha256').update(token).digest 'hex'

# 同じユーザーのトークンが上限を超えていたら、古いものから削除する
enforceTokenLimit = (userid, cb)->
    M.authtokens.find({userid: userid})
        .sort({created: 1, _id: 1})
        .toArray (err, docs)->
            if err?
                cb? err
                return
            excess = docs.length - MAX_TOKENS_PER_USER
            unless excess > 0
                cb?()
                return
            ids = (d._id for d in docs.slice 0, excess)
            M.authtokens.deleteMany {_id: {$in: ids}}, (err2)->
                cb? err2

# トークンを発行（DB にはハッシュと有効期限だけ保存する）
exports.issueToken = (userid, cb)->
    token = crypto.randomBytes(32).toString 'hex'
    doc =
        hash: tokenHash token
        userid: userid
        created: new Date()
        expires: new Date(Date.now() + getTokenExpireMs())
    M.authtokens.insertOne doc, {w:1}, (err)->
        if err?
            cb err
            return
        # 発行後に上限を適用（失敗してもログイン自体は成功させる）
        enforceTokenLimit userid, (err2)->
            console.error err2 if err2?
            cb null, token

# トークン検証。成功時 cb(null, userid)、失敗時 cb(null, null)
exports.verifyToken = (token, cb)->
    unless typeof token == 'string' and /^[0-9a-f]{64}$/.test token
        cb null, null
        return
    M.authtokens.findOne {hash: tokenHash token}, (err, doc)->
        if err?
            cb err
            return
        unless doc? and doc.expires? and doc.expires.getTime() > Date.now()
            cb null, null
            return
        cb null, doc.userid

exports.revokeToken = (token, cb)->
    if typeof token == 'string' and /^[0-9a-f]{64}$/.test token
        M.authtokens.deleteOne {hash: tokenHash token}, (err)->
            cb? err
    else
        cb?()

# パスワード変更時などに、そのユーザーの全トークンを失効させる
exports.revokeAllTokens = (userid, cb)->
    unless userid?
        cb?()
        return
    M.authtokens.deleteMany {userid: userid}, (err)->
        cb? err
