# The extraction component
#
# Each region has the ability to produce the resource.  It will do so under a
# linear cost structure, and at the level set by `pumping`.

using Mimi
using DataFrames

bioclims = readtable("../../../data/bioclims.csv")
bioclims[:fips] = bioclims[:NHGISST] * 100 + bioclims[:NHGISCTY] / 10;

function getallotment(fips, year)
    # Currently ignores year
    row = bioclims[bioclims[:fips] .== parse(Int, fips), :]

    if nrow(row) == 0
        0
    else
        # Smith Kansas is perfectly square and 2,320 km^2, reported as 2.32199e9, so in m
        # Precipitation is in mm / year
        # First, we assume 100% of precipitation is runoff/appropriatable
        (row[1, :bio12_mean] / 1000) * row[1, :SHAPE_AREA]
    end
end

@defcomp Extraction begin
    regions = Index()

    # Internal
    # Freely available (precipitation) water, in 1000 m^3
    free_allotment = Parameter(index=[regions, time])
    # The cost in USD / 1000m^3 of water
    cost_linear = Parameter(index=[regions])

    # Set by optimization
    # Groundwater to pump, in 1000 m^3
    pumping = Parameter(index=[regions, time])

    # The amount extracted: allotment + extracted (1000 m^3)
    extracted = Variable(index=[regions, time])
    # The cost to produce it (USD)
    cost = Variable(index=[regions, time])
end

"""
Compute the amount extracted and the cost for doing it.
"""
function timestep(c::Extraction, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        # Extraction is a copy of pumping
        v.extracted[rr, tt] = p.free_allotment[rr, tt] + p.pumping[rr, tt]
        # Total cost is extraction * cost-per-unit
        v.cost[rr, tt] = v.extracted[rr, tt] * p.cost_linear[rr]
    end
end

"""
The objective of the extraction component is to minimize extraction costs.
"""
function soleobjective_extraction(model::Model)
    sum(model[:Extraction, :cost])
end

"""
Add a extraction component to the model.
"""
function initextraction(m::Model, years)
    extraction = addcomponent(m, Extraction);

    allallotments = Matrix{Float64}(m.indices_counts[:regions], length(years))
    for tt in 1:length(years)
        year = years[tt]
        for ii in 1:m.indices_counts[:regions]
            fips = m.indices_values[:regions][ii]
            allallotments[ii, tt] = getallotment(fips, year)
        end
    end
    extraction[:free_allotment] = allallotments

    # From http://www.oecd.org/unitedstates/45016437.pdf
    # Varies between 6.78 to 140 USD / 1000 m^3
    extraction[:cost_linear] = repmat([100.], m.indices_counts[:regions])

    extraction[:pumping] = zeros(m.indices_counts[:regions], m.indices_counts[:time])

    extraction
end
