using Mimi
using Distributions

include("world.jl")

@defcomp Transportation begin
    regions = Index()
    edges = Index()

    link_capacities = Parameter(index=[edges, time])
    link_costs = Parameter(index=[edges, time])
    costs_overexport = Parameter() # exporting more than you have!

    exported = Parameter(index=[edges, time])

    export_costs = Variable(index=[regions, time]) # Includes over-capacity costs

    # Everything over capacity is lost
    regionimports = Variable(index=[regions, time])
    regionexports = Variable(index=[regions, time])

    produced = Parameter(index=[regions, time])
    marketed = Variable(index=[regions, time])
end

function timestep(c::Transportation, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    realexports = map(min, p.exported[:, tt], p.link_capacities[:, tt])

    v.regionimports = zeros(numcounties, numsteps)

    edge1 = 1
    for ii in 1:numcounties
        numneighbors = out_degree(regverts[names[ii]], regionnet)
        v.export_costs[ii, tt] = sum(p.exported[edge1:edge1 + numneighbors - 1, tt] .* p.link_costs[edge1:edge1 + numneighbors - 1, tt])
        v.regionexports[ii, tt] = sum(realexports[edge1:edge1 + numneighbors - 1])
        dests = getkey(destiis, ii, Int64[])
        for dest in dests
            v.regionimports[dest, tt] += realexports[edge1]
            edge1 += 1 # length(dests) == numneighbors
        end
    end

    v.marketed = p.produced + v.regionimports - v.regionexports
    if any(v.marketed .< 0)
        v.export_costs += (v.marketed .< 0) * p.costs_overexport
        v.regionexports += v.marketed .* (v.marketed .< 0)
        v.marketed[v.marketed .< 0] = 0
    end
end

function soleobjective_transportation(model::Model)
    -sum(model[:Transportation, :export_costs]) # minimize costs
end

function default_exported()
    [100. for i in 1:(numedges*numsteps)]
end

function inittransportation(m::Model)
    transit = addcomponent(m, Transportation)

    transit[:link_capacities] = repeat(Number[1e6], outer=[numedges, numsteps])
    transit[:link_costs] = repeat(convert(Vector{Number}, rand(LogNormal(log(.1), .1), numedges)), outer=[1, numsteps]);
    transit[:costs_overexport] = 1000.0

    transit
end

function newsoletransportation()
    m = newmodel()

    transit = inittransportation(m)

    transit[:produced] = convert(Array{Number, 2}, rand(LogNormal(log(1000.0), 1.), numcounties, numsteps))

    # Default to be overwritten
    transit[:exported] = convert(Array{Number, 2}, rand(LogNormal(log(1000), 100), numedges, numsteps))

    m
end

using OptiMimi

function soletransportation()
    m = newsoletransportation()

    optprob = problem(m, [:Transportation], [:exported], [0.], [1e6], soleobjective_transportation);

    solution(optprob, () -> default_exported())
end
