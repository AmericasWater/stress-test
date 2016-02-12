using Mimi

@defcomp LinearEconomy begin
    regions = Index()
    edges = Index()

    produced = Parameter(index=[regions, time])
    regionimports = Parameter(index=[regions, time])
    regionexports = Parameter(index=[regions, time])

    marketed = Variable(index=[regions, time])
end

function timestep(c::LinearEconomy, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in 1:numcounties
        v.marketed[rr, tt] = p.produced[rr, tt] + p.regionimports[rr, tt] - p.regionexports[rr, tt]
    end
end
