using Mimi

# Region Network definitions

using Graphs

typealias RegionNetwork{R, E} IncidenceList{R, E}
typealias SimpleRegionNetwork RegionNetwork{ExVertex, ExEdge}

empty_regnetwork() = SimpleRegionNetwork(true, ExVertex[], 0, Vector{Vector{ExEdge}}())

using DataFrames

if isfile("../data/regiondests.jld")
    println("Loading from saved region network...")

    regionnet = deserialize(open("../data/regionnet.jld", "r"))
    names = deserialize(open("../data/regionnames.jld", "r"))
    regverts = deserialize(open("../data/regionvertices.jld", "r"))
    destiis = deserialize(open("../data/regiondests.jld", "r"))
else
    # Load the network of counties
    counties = readtable("../../data/county-info.csv", eltypes=[UTF8String, UTF8String, UTF8String, UTF8String, Float64, Float64, Float64, Float64, Float64, Float64, Float64])

    edges = Dict{UTF8String, Vector{UTF8String}}()

    for row in 1:size(counties, 1)
        neighboring = counties[row, :Neighboring]
        if !isna(neighboring)
            chunks = UTF8String[neighboring[start:start+4] for start in 1:5:length(neighboring)]
            fips = counties[row, :FIPS]
            if length(fips) == 4
                fips = "0" * fips
            end

            edges[fips] = chunks
        end
    end

    # Construct the network

    regverts = Dict{UTF8String, ExVertex}()
    names = []
    destiis = Dict{Int64, Vector{Int64}}()
    regionnet = empty_regnetwork()

    for fips in keys(edges)
        regverts[fips] = ExVertex(length(names)+1, fips)
        push!(names, fips)
        add_vertex!(regionnet, regverts[fips])
    end

    for (fips, neighbors) in edges
        for neighbor in neighbors
            if !(neighbor in names)
                # Retroactive add
                regverts[neighbor] = ExVertex(length(names)+1, neighbor)
                push!(names, fips)
                add_vertex!(regionnet, regverts[neighbor])
            end
            add_edge!(regionnet, regverts[fips], regverts[neighbor])
        end
        destiis[indexin([fips], names)[1]] = indexin(neighbors, names)
    end

    serialize(open("../data/regionnet.jld", "w"), regionnet)
    serialize(open("../data/regionnames.jld", "w"), names)
    serialize(open("../data/regionvertices.jld", "w"), regverts)
    serialize(open("../data/regiondests.jld", "w"), destiis)
end

# Prepare the model

numcounties = length(names)
numedges = num_edges(regionnet)
numsteps = 1 #86

function newmodel()
    m = Model(Number)

    setindex(m, :time, collect(2015:2015+numsteps-1))
    setindex(m, :regions, names)
    setindex(m, :edges, collect(1:numedges))

    return m
end
