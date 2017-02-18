exports.start=->
    $("#resetform").submit (je)->
        je.preventDefault()
        form=je.target
        q=
            userid: form.elements["userid"].value
            mail: form.elements["mail"].value
            newpass: form.elements["newpass"].value
            newpass2: form.elements["newpass2"].value
        ss.rpc "user.resetPassword", q,(result)->
            if result?.error?
                $("#resetinfo").text result.error
            if result?.info?
                $("#resetinfo").text result.info