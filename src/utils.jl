

"""
    build_nested_dict(keys::Vector{String}, value::Any)

Build a nested dictionary where the nested level is based on the length of `keys`.
"""
function build_nested_dict(keys, value)

    if length(keys) < 2
        return Dict(keys[1] => value)
    else
        return Dict(keys[1] => build_nested_dict(keys[2:end], value))
    end
end;