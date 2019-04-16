# library to manage players' readiness.
cron = require 'cron'

# time in seconds to reset user's readiness.
READY_RESET_TIME = 5

# map of registered job to reset readiness.
readyResetJobs = new Map

# set user's readiness.
exports.setReady = (ss, roomid, userobj, ready)->
    updateReady(ss, roomid, userobj, ready)
        .then ()->
            # remove previous jobs.
            key = "#{roomid}-#{userobj.realid}"
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

# internal logic to update user's readiness.
updateReady = (ss, roomid, userobj, ready)->
    new Promise (resolve, reject)->
        # save new readiness to DB.
        M.rooms.update {
            id: roomid
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
