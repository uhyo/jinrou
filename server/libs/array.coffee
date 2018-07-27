# Remove duplicate element of sorted array.
exports.sortedUnique = (arr)->
    if arr.length <= 1
        return arr
    result = [arr[0]]
    last = arr[0]
    for i in [1...(arr.length)]
        if arr[i] != last
            result.push arr[i]
            last = arr[i]
    return result

