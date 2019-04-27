Shared=
    game:require '../../client/code/shared/game.coffee'

# fill partially filled joblist.
exports.fillJoblist = (joblist)->
    for job in Shared.game.jobs
        joblist[job] ?= 0
    for cat of Shared.game.categories
        joblist["category_#{cat}"] ?= 0
    joblist

# count all jobs in joblist.
exports.countJobsInJoblist = (joblist)->
    sum = 0
    for job in Shared.game.jobs
        sum += (joblist[job] ? 0)
    for cat of Shared.game.categories
        sum += (joblist["category_#{cat}"] ? 0)
    sum

# randomly replaces roles in joblist to categories.
# used in easy yaminabe.
exports.easyReplaceJoblist = (joblist)->
    rolesArr = []
    players = 0
    console.log "before", joblist
    for job in Shared.game.jobs
        players += joblist[job]
        for _ in [0...joblist[job]]
            rolesArr.push job
    picked = if players >= 10 then 2 else 1
    for _ in [0 ... picked]
        r = Math.floor Math.random() * rolesArr.length
        [picked] = rolesArr.splice r, 1
        jobCat = getJobCategory picked
        # 基本は同じカテゴリに入れ替わるが
        # Humanの場合はOthersとかSwitchingになることもある
        newCat = if jobCat != "Human"
            jobCat
        else
            rnd = Math.random()
            if rnd < 0.7
                "Human"
            else if rnd < 0.85
                "Others"
            else
                "Switching"
        joblist["category_#{newCat}"] = 1 + (joblist["category_#{newCat}"] ? 0)
        joblist[picked]--
    console.log "after", joblist
    joblist


# get category of given job.
getJobCategoryCache = new Map
getJobCategory = (job)->
    c = getJobCategoryCache.get job
    if c != undefined
        return c
    for cat, jobsinCategory of Shared.game.categories
        if job in jobsinCategory
            getJobCategoryCache.set job, cat
            return cat
    getJobCategoryCache.set job, null
    return null

