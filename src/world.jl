using Mimi

# Region Network definitions

using Graphs

# Only include counties within this state (give as 2 digit FIPS)
filterstate = nothing #"08"

typealias RegionNetwork{R, E} IncidenceList{R, E}
typealias SimpleRegionNetwork RegionNetwork{ExVertex, ExEdge}
typealias MyNumeric Float64 #Number

function asmynumeric(array, dims=1)
    if MyNumeric == Float64
        return array
    else
        return convert(Array{MyNumeric, dims}, array)
    end
end

# Region network has OUT nodes to potential sources for IMPORT

empty_regnetwork() = SimpleRegionNetwork(true, ExVertex[], 0, Vector{Vector{ExEdge}}())

using DataFrames

suffix = (filterstate != nothing ? "-$filterstate" : "")

if isfile("../data/regionsources$suffix.jld")
    println("Loading from saved region network...")

    regionnet = deserialize(open("../data/regionnet$suffix.jld", "r"))
    names = deserialize(open("../data/regionnames$suffix.jld", "r"))
    regverts = deserialize(open("../data/regionvertices$suffix.jld", "r"))
    sourceiis = deserialize(open("../data/regionsources$suffix.jld", "r"))
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

            # Only include if part of filter
            if filterstate != nothing
                if fips[1:2] == filterstate
                    edges[fips] = filter(ff -> ff[1:2] == filterstate, chunks)
                end
            else
                edges[fips] = chunks
            end
        end
    end

    # Construct the network

    regverts = Dict{UTF8String, ExVertex}()
    names = []
    sourceiis = Dict{Int64, Vector{Int64}}()
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
                push!(names, neighbor)
                add_vertex!(regionnet, regverts[neighbor])
            end
            add_edge!(regionnet, regverts[fips], regverts[neighbor])
        end
        sourceiis[indexin([fips], names)[1]] = indexin(neighbors, names)
    end

    serialize(open("../data/regionnet$suffix.jld", "w"), regionnet)
    serialize(open("../data/regionnames$suffix.jld", "w"), names)
    serialize(open("../data/regionvertices$suffix.jld", "w"), regverts)
    serialize(open("../data/regionsources$suffix.jld", "w"), sourceiis)
end

# Prepare the model

#numcounties = length(names)
#numedges = num_edges(regionnet)
#numsteps = 1 #86

function newmodel(ns)
    #global numsteps = ns

    m = Model(MyNumeric)

    setindex(m, :time, collect(2015:2015+ns-1))
    setindex(m, :regions, names)
    setindex(m, :edges, collect(1:num_edges(regionnet)))

    return m
end
