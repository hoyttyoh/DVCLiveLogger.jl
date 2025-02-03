##
using DVCLiveLogger
using Logging
using Dates
#include("live.jl")
#include("dvc.jl")
#include("handlers.jl")

##

d = Dict(
    "epochs" => 2000
)
epochs=Int32(d["epochs"])

lr = 0.001
lg = LiveLogger(save_dvc_exp=false, resume=true)
t1 = now()

with_logger(lg) do
   
    @param "epochs" epochs
    @param "lr" lr
    @param "x" 2.2
    @params a=2 b=3 c=3

    for i in 1:100
        #@metric "start_time" 123456 plot=false
        @metric "train/acc" rand() plot=true
        @metric "eval/acc" rand()
        @metric "test/acc" rand()
        #@metric "time" 1.0 plot=false

        next_step!(lg)
    end
    t2 = now()
    t = t2-t1
    @metric "time" t.value plot=false
    @artifact "model.keras" name="test_model" desc="nothing special" labels=["v0.4.0", "test"]
    @artifact "mode2.keras" name="another model"
end