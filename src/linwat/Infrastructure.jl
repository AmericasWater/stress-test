# The infrastructure component
#
# Determines the available resource for consumption, as a balance between local
# production, imports, and exports.

using Mimi

@defcomp Infrastructure begin
    regions = Index()
    edges = Index()

    # External
    # Local production from Production
    extracted = Parameter(index=[regions, time])
    # Imports and exports from Transportation
    regionimports = Parameter(index=[regions, time])
    regionexports = Parameter(index=[regions, time])

    # The balance of available resource
    available = Variable(index=[regions, time])
end

"""
Compute the available local resource for consumption, `available`.
"""
function timestep(c::Infrastructure, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        v.available[rr, tt] = p.extracted[rr, tt] + p.regionimports[rr, tt] - p.regionexports[rr, tt]
    end
end
