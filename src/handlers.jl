
##
using CSV
using Base: CoreLogging

macro metric(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:MetricLevel, exs...) end;

macro param(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:ParamLevel, exs...) end;

macro params(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:ParamsLevel, exs...) end;

macro artifact(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:ArtifactLevel, exs...) end;

macro status(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:StatusLevel, exs...) end;
    

function dvc_code(_module, file, line, level, exs...)
    
    group = CoreLogging.default_group_code(file)

    kwargs=[]
    
    for ex in exs
   
        if ex isa Expr && ex.head === :(=)
            k,v = ex.args
            push!(kwargs,Expr(:kw, Symbol(k), esc(v)))
        end
    end

    if level==:MetricLevel
        return quote
            logger = CoreLogging.current_logger_for_env(MetricLevel, $group, $_module)
            log_metric(logger, $exs[1], $(esc(exs[2])); $(kwargs...))
        end

    end

    if level==:ParamLevel
        return quote
            logger = CoreLogging.current_logger_for_env(ParamLevel, $group, $_module)
            log_param(logger, $exs[1], $(esc(exs[2])); $(kwargs...))
        end
    end

    if level==:ParamsLevel
        return quote
            logger = CoreLogging.current_logger_for_env(ParamLevel, $group, $_module)
            log_params(logger;$(kwargs...))
        end
    end

    if level==:ArtifactLevel
        return quote
            logger = CoreLogging.current_logger_for_env(ParamLevel, $group, $_module)
            log_artifact(logger, $(esc(exs[1])); $(kwargs...))
        end
    end

    if level==:StatusLevel
        return quote
            show_status($(esc(exs[1])); $(kwargs...))
        end
    end
end

function show_status(msg)
    println(msg)
end

function log_metric(logger::LiveLogger, name, value; kwargs...)

    update_metrics!(logger, name, value)

    plot = get(Dict(kwargs),:plot,true)
    mplotf = metric_plot_file(logger, name)

    if plot===true
        delim = "\t"
        append = (logger.step>1 || logger.resume) ? true : false
        data = (step=[logger.step], name=[value])
        header = ["step", last(split(name,"/"))]

        CSV.write(
            mplotf, 
            data, 
            delim=delim, 
            append=append, 
            header=header
            )
    end
    return nothing

end

function log_param(logger::LiveLogger, name, value; kwargs...)

    update_params!(logger, name, value)

end;

function log_params(logger::LiveLogger; kwargs...)
    for (k,v) in pairs(kwargs)
        log_param(logger,k,v)
    end
end;

function log_artifact(logger::LiveLogger, path; kwargs...) 

    update_artifacts!(logger, path; kwargs...)
    dvc_add(path)

    return nothing

end;


function CoreLogging.with_logger(@nospecialize(f::Function), logger::LiveLogger)

    @nospecialize
    t = current_task()
    old_logstate = t.logstate

    try
        t.logstate = CoreLogging.LogState(logger)
        f()
        end_live(logger)

    finally
        t.logstate = old_logstate
    end
end
