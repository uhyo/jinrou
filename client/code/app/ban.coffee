# client-side ban handling

# Save data to storage.
exports.saveBanData = (banid)->
    data = btoa banid
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
    openDb (db)->
        unless db?
            cb {error: "failed"}
            return
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

# Load data from storage.
exports.loadBanData = (cb)->
    ls = read_data load_from_localStorage()
    if ls?
        cb ls
        return
    c = read_data load_from_cookie()
    if c?
        cb c
        return
    load_from_indexeddb (data)->
        i = read_data data
        if i?
            cb i
        else
            cb null

load_from_localStorage = ()->
    localStorage.bclient_id

load_from_cookie = ()->
    r = document.cookie.match(new RegExp "(?:^|.*;\\s*)bclient_session\\s*\\=\\s*((?:[^;](?!;))*[^;]?).*")
    if r?
        return decodeURIComponent r[1]
    return null

load_from_indexeddb = (cb)->
    openDb (db)->
        unless db?
            cb {error: "failed"}
            return
        t = db.transaction "client", "readonly"
        s = t.objectStore "client"
        
        req2 = s.get "b"
        req2.onerror = ()->
            console.error req2.error
            cb null
        req2.onsuccess = ()->
            if req2.result
                cb req2.result.value
            else
                cb null
        t.onerror = ()->
            console.error t.error
            cb null

# check.
read_data = (data)->
    unless "string" == typeof data
        return null
    try
        b = atob data
        return b
    catch e
        console.error e
        return null

# remove Ban data.
exports.removeBanData = ()->
    localStorage.removeItem "bclient_id"
    document.cookie = "bclient_session=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
    if "undefined" == typeof indexedDB
        return
    openDb (db)->
        unless db?
            cb {error: "failed"}
            return
        t = db.transaction "client", "readwrite"
        s = t.objectStore "client"
        
        req2 = s.delete "b"
        req2.onerror = ()->
            console.error req2.error
        t.onerror = ()->
            console.error t.error

# Open jinrou database.
openDb = (cb)->
    if "undefined" == typeof indexedDB
        console.warn "No IndexedDB support."
        cb null
        return
    req = indexedDB.open "jinrou_session", 1
    req.onerror = ()->
        console.error req.error
        cb null
    req.onupgradeneeded = (e)->
        db = req.result
        old = e.oldVersion
        if old < 1
            db.createObjectStore "client", {
                keyPath: "id"
                autoIncrement: false
            }
    req.onsuccess = ()->
        cb req.result
