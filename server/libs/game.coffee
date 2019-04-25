Shared=
    game:require '../../client/code/shared/game.coffee'


# Validate gameStart query.
# Returns null if valid.
# Otherwise returns an error object.
exports.validateGameStartQuery = (game, query)->
    rules = iterRules Shared.game.new_rules
    for rule in rules
        # TODO
        switch rule.type
            when "select"
                unless query[rule.id] in rule.values
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "checkbox"
                unless query[rule.id] in ["", rule.value]
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "time"
                # time should be parseable number.
                val = parseInt query[rule.id]
                unless Number.isInteger val
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
                if rule.minValue? && val < rule.minValue
                    return {
                        rule: rule.id
                        errorType: "tooSmall"
                    }
            when "hidden"
                # hidden rule is for backwards compatibility.
                unless query[rule.id] == rule.value
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
            when "integer"
                val = parseInt query[rule.id]
                unless Number.isInteger val
                    return {
                        rule: rule.id
                        errorType: "invalid"
                    }
                if rule.minValue? && val < rule.minValue
                    return {
                        rule: rule.id
                        errorType: "tooSmall"
                    }
    null

# Returns a list of jobs sorted by category.
categorySortedJobsCache = null
exports.categorySortedJobs = ()->
    if categorySortedJobsCache?
        return categorySortedJobsCache
    jobsObject = {}
    for job in Shared.game.jobs
        jobsObject[job] = true

    categorySortedJobsCache = []
    for cat, js of Shared.game.categories
        for job in js
            if jobsObject[job]
                categorySortedJobsCache.push job
    return categorySortedJobsCache


# Make a list of all rules.
iterRules = (rules)->
    result = []
    for obj in rules
        if obj.type == "group"
            result.push iterRules(obj.items)...
        else if obj.type == "item"
            result.push obj.value
    return result

