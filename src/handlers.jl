
##
using CSV
using Base: CoreLogging

macro metric(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:MetricLevel, exs...) end;

macro param(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:ParamLevel, exs...) end;

macro params(exs...) dvc_code((CoreLogging.@_sourceinfo)...,:ParamsLevel, exs...) end;

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
        handle_metric(logger, $exs[1], eval($exs[2]); $(kwargs...))
        end

    end

    if level==:ParamLevel
        return quote
        logger = CoreLogging.current_logger_for_env(ParamLevel, $group, $_module)
        handle_param(logger, $exs[1], eval($exs[2]); $(kwargs...))
        end
    end

    if level==:ParamsLevel
        return quote
        logger = CoreLogging.current_logger_for_env(ParamLevel, $group, $_module)
        handle_params(logger;$(kwargs...))
        end
    end

end


function handle_metric(logger, name, value; kwargs...)
  
    update_metric!(logger, name, value)
    plot = get(Dict(kwargs),:plot,true)
    mplotf = metric_plot_file(logger,name)

    if plot==true
        delim = "\t"
        append = (logger.step>1 | logger.resume) ? true : false
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

end

function handle_param(logger, name, value; kwargs...)

    update_param!(logger, name, value)

    save_params(logger)

end;

function handle_params(logger; kwargs...)
    for (k,v) in pairs(kwargs)
        handle_param(logger,k,v)
    end
end;

function handle_artifact(logger, artifact) end;



