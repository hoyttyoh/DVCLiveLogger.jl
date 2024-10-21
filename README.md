```julia
logger = DvcLiveLogger()

with_logger(logger) do

    epochs=100
    lr = 0.001
    
    @param "learning_rate" lr
    @param "epochs" epochs

    for i in 1:epochs

        x,y = evaluate(something)

        @metric "test/acc" x 
        @metric "train/acc" y

        next_step!(logger)

    end

end


    ```