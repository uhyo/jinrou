# client-side ban handling

exports.saveBanData = (banid)->
    data = add_checksum (btoa banid)
    save_in_localStorage data
    save_in_cookie data
    save_in_indexeddb data, (err)->
        if err?
            console.error err

save_in_localStorage = (data)->
    localStorage.bclient_id = data

save_in_cookie = (data)->
    document.cookie = "bclient_session=#{encodeURIComponent data}; path=/; max-age=31536000"

save_in_indexeddb = (data, cb)->
    if "undefined" == typeof indexedDB
        cb {error: "No IndexedDB Support."}
        return
    req = indexedDB.open "jinrou_session", 1
    req.onerror = ()->
        cb {error: req.error}
    req.onupgradeneeded = (e)->
        db = req.result
        old = e.oldVersion
        if old < 1
            db.createObjectStore "client", {
                keyPath: "id"
                autoIncrement: false
            }

    req.onsuccess = ()->
        db = req.result
        t = db.transaction "client", "readwrite"
        s = t.objectStore "client"
        req2 = s.put {
            id: "b"
            value: data
        }
        req2.onsuccess = ()->
            cb null
        req2.onerror = ()->
            cb {error: req2.error}
        t.onerror = ()->
            cb {error: t.error}


# add a checksum to Base64-encoded data
add_checksum = (data)->
    l = data.length
    sum = 0
    for i in [0...l]
        sum += data.charCodeAt i
    c = String(sum % 10)
    return data + c
