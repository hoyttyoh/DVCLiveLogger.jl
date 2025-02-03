

function dvc_exp_save(logger::LiveLogger)

    if isnothing(logger.exp_name)
        cmd = `dvc exp save`
    else
        cmd = `dvc exp save -n $(logger.exp_name)`
    end

    run(cmd)

    return nothing

end

function dvc_add(path)

    if isfile(path)

        cmd = `dvc add $(path)`

        run(cmd)
       
    else
        @error "No artifact found: $(path)"
    end

    return nothing

end

