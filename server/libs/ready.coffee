# library to manage players' readiness.
cron = require 'cron'

# time in seconds to reset user's readiness.
READY_RESET_TIME = 300

# map of registered job to reset readiness.
readyResetJobs = new Map

# set user's readiness.
exports.setReady = (ss, roomid, userobj, ready)->
    updateReady(ss, roomid, userobj, ready)
        .then ()->
            # remove previous jobs.
            key = jobsKey roomid, userobj.realid
            previousJob = readyResetJobs.get key
            if previousJob?
                previousJob.stop()
            resetReadyDate = new Date
            resetReadyDate.setSeconds resetReadyDate.getSeconds() + READY_RESET_TIME

            if ready
                jobTick = ()->
                    # after READY_RESET_TIME seconds, reset ready to false.
                    updateReady ss, roomid, userobj, false
                    readyResetJobs.delete key
                job = new cron.CronJob resetReadyDate, jobTick
                job.start()
                readyResetJobs.set key, job
            else
                readyResetJobs.delete key
# reset readiness of all players.
exports.unreadyAll = (ss, roomid, players)->
    new Promise (resolve, reject)->
        for p in players
            p.start = false
            untrack roomid, p.realid
        # update whole players array at once.
        M.rooms.update {
            id: roomid
            mode: "waiting"
        }, {
            $set: {
                players: players
            }
        }, (err)->
            if err?
                reject err
                return
            ss.publish.channel "room#{roomid}", "unreadyall", {}
            resolve()

# unregister a user from readiness management.
exports.unregister = (roomid, userobj)->
    untrack roomid, userobj.realid

# make a key from roomid and realid.
jobsKey = (roomid, realid)-> "#{roomid}-#{realid}"

# internal logic to untrack user.
untrack = (roomid, realid)->
    key = jobsKey roomid, realid
    previousJob = readyResetJobs.get key
    previousJob?.stop()
    readyResetJobs.delete jobsKey(roomid, realid)

# internal logic to update user's readiness.
updateReady = (ss, roomid, userobj, ready)->
    new Promise (resolve, reject)->
        # save new readiness to DB.
        M.rooms.update {
            id: roomid
            mode: "waiting"
            "players.realid": userobj.realid
        }, {
            $set: {
                "players.$.start": ready
            }
        }, (err)->
            if err?
                reject err
                return
            # 参加者たちに知らせる
            ss.publish.channel "room#{roomid}", "ready", {
                userid: userobj.userid
                start: ready
            }
            resolve()
