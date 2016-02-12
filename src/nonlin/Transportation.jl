using Mimi
using Distributions

include("world.jl")

# Reinterpret Transportation to be all imports
@defcomp Transportation begin
    regions = Index()
    edges = Index()

    link_capacities = Parameter(index=[edges, time])
    link_costs = Parameter(index=[edges, time]) # Per unit

    imported = Parameter(index=[edges, time])

    realimports = Variable(index=[edges, time])
    transportspending = Variable(index=[edges, time]) # Total spent on transport

    # Everything over capacity is lost
    regionimports = Variable(index=[regions, time])
    regionexports = Variable(index=[regions, time])

    balance = Variable(index=[regions, time])
end

function timestep(c::Transportation, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for ee in 1:numedges
        v.realimports[ee, tt] = min(p.imported[ee, tt], p.link_capacities[ee, tt])
        v.transportspending[ee, tt] = p.imported[ee, tt] * p.link_costs[ee, tt]
    end

    edge1 = 1
    for ii in 1:numcounties
        numneighbors = out_degree(regverts[names[ii]], regionnet)
        #v.import_spending[ii, tt] = sum(p.imported[edge1:edge1 + numneighbors - 1, tt] .* p.link_costs[edge1:edge1 + numneighbors - 1, tt]) # Don't use this any more; keep at the edge level
        v.regionimports[ii, tt] = sum(v.realimports[edge1:edge1 + numneighbors - 1, tt])

        sources = get(sourceiis, ii, Int64[])
        for source in sources
            v.regionexports[source, tt] += v.realimports[edge1, tt]
            edge1 += 1 # length(sources) == numneighbors
        end

        v.balance[ii, tt] = v.regionimports[ii, tt] - v.regionexports[ii, tt]
    end
end

function soleobjective_transportation(model::Model)
    -sum(model[:Transportation, :import_spending]) # minimize costs
end

function default_exported()
    [100. for i in 1:(numedges*numsteps)]
end

function inittransportation(m::Model)
    transit = addcomponent(m, Transportation)

    transit[:link_capacities] = repeat(MyNumeric[1e6], outer=[numedges, numsteps])
    transit[:link_costs] = repeat(convert(Vector{MyNumeric}, rand(LogNormal(log(.1), .1), numedges)), outer=[1, numsteps]);

    transit
end

function newsoletransportation()
    m = newmodel(1)

    transit = inittransportation(m)

    # Default to be overwritten
    transit[:imported] = convert(Array{MyNumeric, 2}, rand(LogNormal(log(1000), 100), numedges, numsteps))

    m
end

using OptiMimi

function soletransportation()
    m = newsoletransportation()

    optprob = problem(m, [:Transportation], [:imported], [0.], [1e6], soleobjective_transportation);

    solution(optprob, () -> default_exported())
end
