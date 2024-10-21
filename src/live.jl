using Logging
using YAML
using JSON

const MetricLevel = AboveMaxLevel + 1
const ParamLevel = MetricLevel + 1
const ParamsLevel = ParamLevel + 1
const ArtifactLevel = ParamsLevel + 1


mutable struct DvcLiveLogger <: AbstractLogger
    dir::String
    resume::Bool
    dvcyaml::Union{String,Nothing}
    save_dvc_exp::Bool
    exp_name::Union{String,Nothing}
    exp_msg::Union{String,Nothing}
    step::Int
    metrics::Dict{Any,Any}
    params::Dict{Any,Any}
end

DvcLiveLogger(;dir="dvclive",resume=false, dvcyaml="dvc.yaml", save_dvc_exp=true)=DvcLiveLogger(dir, resume, dvcyaml, save_dvc_exp, nothing, nothing, 1, Dict(),Dict());

metrics_plot_dir(logger) = joinpath(logger.dir,"plots","metrics")

function check_metrics_plot_dir(logger)
    _plot_dir = metrics_plot_dir(logger)
    !isdir(_plot_dir) && mkpath(_plot_dir)

    return _plot_dir
end

# create the metric file for plotting if not exist and not continue
# one for each metric?
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


Logging.shouldlog(logger::DvcLiveLogger, level, args...)= true

Logging.min_enabled_level(logger::DvcLiveLogger) = MetricLevel

function next_step!(logger)

    make_summary(logger)
    make_dvcyaml(logger)

    logger.step+=1

end

function make_dvcyaml(logger)

    dvcyaml = Dict()
    
    dvcyaml["params"] = [joinpath(logger.dir,"params.yaml")]
    dvcyaml["metrics"] = [joinpath(logger.dir,"metrics.json")]

    dvcyaml_plots = Dict()
    dvcyaml_plots[metrics_plot_dir(logger)] = Dict("x" => "step")

    dvcyaml["plots"] = [dvcyaml_plots]

    YAML.write_file("dvc.yaml", dvcyaml)

end

function make_summary(logger)

    summ = Dict()
    summ["step"] = logger.step

    for (k,v) in pairs(logger.metrics)
        ksplit = split(k,"/")
        dke = build_nested_dict(ksplit,v)
        merge!(summ, dke)
    end

    jfile = joinpath(logger.dir,"metrics.json")
    open(jfile, "w") do f
        JSON.print(f, summ)
    end

    return nothing

end

function update_metric!(logger, name, value)

    logger.metrics[name] = value

    return nothing

end

function update_param!(logger, name, value)

    logger.params[name] = value

    return nothing
end

function update_params!(logger, p::Dict)

    for (k,v) in pairs(p)
        update_param!(logger, k, v)
    end

    return nothing
end

function save_params(logger)

    pfile = joinpath(logger.dir,"params.yaml")
    YAML.write_file(pfile, logger.params)

end

function save_dvc_exp(logger)

    if isnothing(logger.exp_name)
        cmd = `dvc exp save`
    else
        cmd = `dvc exp save -n $(logger.exp_name)`
    end

    run(cmd)

end

current_step(logger)=logger.step;


function build_nested_dict(keys, value)
    if length(keys) == 1
        return Dict(keys[1] => value)
    else
        return Dict(keys[1] => build_nested_dict(keys[2:end], value))
    end
end;

function end_live(logger)

    if logger.save_dvc_exp
        save_dvc_exp(logger)
    end

    return nothing
end
