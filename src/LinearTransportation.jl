using Mimi
using Distributions

@defcomp LinearTransportation begin
    regions = Index()
    edges = Index()

    # Internal
    link_costs = Parameter(index=[edges, time])

    # Set by optimiation
    imported = Parameter(index=[edges, time])

    costs = Variable(index=[edges, time])

    regionimports = Variable(index=[regions, time])
    regionexports = Variable(index=[regions, time])
end

function timestep(c::LinearTransportation, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for ee in 1:numedges
        v.costs[ee, tt] = p.imported[ee, tt] * p.link_costs[ee, tt]
    end

    edge1 = 1
    for ii in 1:numcounties
        numneighbors = out_degree(regverts[names[ii]], regionnet)

        v.regionimports[ii, tt] = sum(p.imported[edge1:edge1 + numneighbors - 1, tt])

        v.regionexports[ii, tt] = 0.0
        sources = get(sourceiis, ii, Int64[])
        for source in sources
            v.regionexports[source, tt] += p.imported[edge1, tt]
            edge1 += 1 # length(sources) == numneighbors
        end
    end
end

function soleobjective_transportation(model::Model)
    sum(model[:LinearTransportation, :costs]) # minimize costs
end

default_imported() = [0. for i in 1:numedges*numsteps]

function inittransportation(m::Model)
    transit = addcomponent(m, LinearTransportation)

    transit[:link_costs] = repeat(convert(Vector{MyNumeric}, rand(LogNormal(log(.1), .1), numedges)), outer=[1, numsteps]);

    transit
end
