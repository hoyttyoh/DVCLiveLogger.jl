using Logging
using YAML
using JSON
using UUIDs
using Mocking: @mock

const MetricLevel = AboveMaxLevel + 1
const ParamLevel = MetricLevel + 1
const ParamsLevel = ParamLevel + 1
const ArtifactLevel = ParamsLevel + 1
const StatusLevel = ArtifactLevel + 1

mutable struct LiveLogger <: AbstractLogger
    dir::String
    resume::Bool
    dvcyaml::Union{String,Nothing}
    save_dvc_exp::Bool
    exp_name::Union{String,Nothing}
    exp_msg::Union{String,Nothing}
    step::Int
    metrics::Dict{Any,Any}
    params::Dict{Any,Any}
    artifacts::Dict{Any,Any}
end

function LiveLogger(;dir="dvclive",resume=false, dvcyaml="dvc.yaml", save_dvc_exp=true)
    
    lg = LiveLogger(dir, resume, dvcyaml, save_dvc_exp, nothing, nothing, 1, Dict(),Dict(),Dict());
    if resume===true
        resume!(lg)
    end

    lg
end


metrics_plot_dir(logger) = joinpath(logger.dir,"plots","metrics")

function check_metrics_plot_dir(logger)
    check_dir_exists(logger)
    _plot_dir = metrics_plot_dir(logger)
    !isdir(_plot_dir) && mkpath(_plot_dir)

    return _plot_dir
end


function metric_plot_file(logger, metric, ftype="tsv") 

    _plot_dir = check_metrics_plot_dir(logger)
    _metric = split(metric,"/")
    _metric_file = pop!(_metric)

    if !isempty(_metric)
        _plot_dir = joinpath(_plot_dir,_metric[1:end]...)
        mkpath(_plot_dir)
    end

    f = joinpath(_plot_dir,_metric_file*"."*ftype)

    if isfile(f) && logger.resume==false && logger.step==1
        rm(f)
    end

    return f

end;


Logging.shouldlog(logger::LiveLogger, level, args...)= true

Logging.min_enabled_level(logger::LiveLogger) = MetricLevel

function next_step!(logger)

    @mock make_summary(logger)
    @mock make_dvcyaml(logger)

    logger.step+=1

end
"""
    make_dvcyaml(logger)

Write `dvc.yaml` to file.
"""  
function make_dvcyaml(logger)

    if logger.dvcyaml === nothing
        return nothing
    end

    !isdir(dirname(logger.dvcyaml)) && mkpath(dirname(logger.dvcyaml))
    
    dvcyaml = Dict()

    dvcyaml["params"] = [joinpath(logger.dir,"params.yaml")]
    dvcyaml["metrics"] = [joinpath(logger.dir,"metrics.json")]

    dvcyaml_plots = Dict()
    dvcyaml_plots[metrics_plot_dir(logger)] = Dict("x" => "step")

    dvcyaml["plots"] = [dvcyaml_plots]

    dvcyaml["artifacts"] = logger.artifacts

    YAML.write_file(logger.dvcyaml, dvcyaml)
    
    return nothing

end

"""
    make_summary(logger)

Write `params.yaml` and `metrics.json` to the `dvclive` directory.
""" 
function make_summary(logger)

    save_params(logger)
    save_metrics(logger)

    return nothing

end

function update_metrics!(logger, name, value)

    logger.metrics[name] = value

    return nothing

end

function resume!(logger)

    try
        pfile = joinpath(logger.dir,"params.yaml")
        open(pfile, "r") do f
            logger.params = YAML.load(f)
        end
    catch
        @warn "No params file found."
    end

    try
        jfile = joinpath(logger.dir,"metrics.json")
        open(jfile, "r") do f
            logger.metrics = JSON.parse(f)
            logger.step = get(logger.metrics,"steps",0)
        end
    catch
        @warn "No metrics file found."
    end

    try
        if isnothing(logger.dvcyaml)
            @debug "No dvc.yaml file specified."
        else
            dvcyaml = YAML.load_file(logger.dvcyaml)
            logger.artifacts = get(dvcyaml,"artifacts",Dict())
        end
    catch
        @warn "No dvc.yaml file found."
    end

    return nothing
end

function update_params!(logger, name, value)

    logger.params[name] = value

    return nothing
end

function update_params!(logger, p::Dict)

    for (k,v) in pairs(p)
        update_param!(logger, k, v)
    end

    return nothing
end

function update_artifacts!(logger, path; kwargs...)

    kw = Dict(kwargs)

    name = get(kw,:name,string(uuid4()))
    desc = get(kw, :desc, "")
    type = get(kw, :type, "")
    labels = get(kw, :labels, [])
    meta = get(kw, :meta, Dict())

    art = Dict()
    art[name] = Dict(
        "path" => path,
        "desc" => desc,
        "type" => type,
        "labels" => labels isa Vector ? labels : [labels],
        "meta" => meta
    )

    merge!(logger.artifacts, art)

    return nothing

end

function check_dir_exists(logger)
    ispath(logger.dir) || mkdir(logger.dir)
end

function save_params(logger)

    check_dir_exists(logger)

    pfile = joinpath(logger.dir,"params.yaml")

    isfile(pfile) || touch(pfile)
    
    YAML.write_file(pfile, logger.params)
    return nothing
end

function save_metrics(logger)

    check_dir_exists(logger)

    summ = Dict()
    summ["steps"] = logger.step

    temp = []
    for (k,v) in pairs(logger.metrics)
        ksplit = split(k,"/")
        dke = build_nested_dict(ksplit,v)
        push!(temp, dke)
    end

    mtemp = mergewith(merge, temp...)
    merge!(summ, mtemp)

    jfile = joinpath(logger.dir,"metrics.json")
    open(jfile, "w") do f
        JSON.print(f, summ)
    end

end

current_step(logger)=logger.step;

"""
    end_live(logger)

End the `DVCLive` logging.

Creates a summary and 

"""
function end_live(logger)

    make_dvcyaml(logger)
    make_summary(logger)

    if logger.save_dvc_exp
        dvc_exp_save(logger)
    end

    return nothing
end
