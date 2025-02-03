# DVCLive Logger
[DVC](https://dvc.org/doc) is a tool for tracking large datasets and machine learning
models. It provides a Python API module ([`dvclive`](https://dvc.org/doc/dvclive)) that can
be used to log parameters, metrics and other metadata produced over the course of training
and evaluating a machine learning
model.

This is a bare-bones Julia implementation of a `LiveLogger <: AbstractLogger` that is
intended to provide similar functionality to the `Live()` python class while meeting the
Julia base [Logging](https://docs.julialang.org/en/v1.11/stdlib/Logging/) module interface.

# Functionality
<center>

| Loggable Feature | Implemented |
|---------:|:-----------:|
| metrics | Y |
| parameters | Y |
| artifacts | Y |
| plots | N |
| images | N |

</center>

# Example Usage
```julia
using DVCLiveLogger

dvc_logger = LiveLogger()

with_logger(dvc_logger) do

    epochs=100
    lr = 0.001

    @param "learning_rate" lr
    @param "epochs" epochs

    for i in 1:epochs

        x,y = evaluate(something)

        @metric "test/acc" x 
        @metric "train/acc" y

        next_step!(dvc_logger)

    end

end


    ```