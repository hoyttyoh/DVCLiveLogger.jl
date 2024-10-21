##

include("live.jl")
include("handlers.jl")

##

lg = DvcLiveLogger(save_dvc_exp=true)
with_logger(lg) do
    @param "epochs" 100
    @param "lr" 0.003
    @params a=2 b=3 c=3

    for i in 1:100
        @metric "start_time" 123456 plot=false
        @metric "train/acc" rand() plot=true
        @metric "eval/acc" rand()

        next_step!(lg)
    end
end