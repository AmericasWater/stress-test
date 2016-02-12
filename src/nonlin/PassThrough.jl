@defcomp PassThrough begin
    regions = Index()

    input = Parameter(index=[regions, time])
    output = Variable(index=[regions, time])
end

function timestep(c::PassThrough, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        v.output[rr, tt] = p.input[rr, tt]
    end
end
