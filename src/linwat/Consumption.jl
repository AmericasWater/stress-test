# The consumption component
#
# Each region has an `demand`, and compares this to the amount of `available`
# resource.  The result is a `surplus`, which may be negative if `available` <
# `demand`.

using Mimi
using DataFrames

populations = readtable("../../../data/county-pops.csv", eltypes=[Int64, UTF8String, UTF8String, Int64, Float64]);

function getpopulation(fips, year)
    pop = populations[(populations[:FIPS] .== parse(Int64, fips)) & (populations[:year] .== year), :population]
    if length(pop) != 1
        NA
    else
        pop[1]
    end
end

@defcomp Consumption begin
    regions = Index()

    # Internal
    # Resource demands
    demandperperson = Parameter()
    population = Parameter(index=[regions, time])

    # External
    # Resource availability from Infrastructure
    available = Parameter(index=[regions, time])

    # Resource surplus over (or below) demand
    demand = Variable(index=[regions, time])
    surplus = Variable(index=[regions, time])
end

"""
Compute the `surplus` as `available` - `demand`.
"""
function timestep(c::Consumption, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        v.demand[rr, tt] = p.population[rr, tt] * p.demandperperson
        v.surplus[rr, tt] = p.available[rr, tt] - v.demand[rr, tt]
    end
end

"""
Add a consumption component to the model.
"""
function initconsumption(m::Model, years)
    consumption = addcomponent(m, Consumption)

    # Virtual water from http://hdr.undp.org/sites/default/files/reports/267/hdr06-complete.pdf
    # Blue water from http://waterfootprint.org/media/downloads/Hoekstra_and_Chapagain_2006.pdf
    consumption[:demandperperson] = 2480. + 575 * 365.25 * .001 # m^3 / yr

    allpops = Matrix{Float64}(m.indices_counts[:regions], length(years))
    totalpop = 0
    for tt in 1:length(years)
        year = years[tt]
        for ii in 1:m.indices_counts[:regions]
            fips = m.indices_values[:regions][ii]
            pop = getpopulation(fips, year)
            if isna(pop) && mod(year, 10) != 0
                # Estimate from decade
                pop0 = getpopulation(fips, div(year, 10) * 10)
                pop1 = getpopulation(fips, (div(year, 10) + 1) * 10)
                pop = pop0 * (1 - mod(year, 10) / 10) + pop1 * mod(year, 10) / 10
            end
            if isna(pop)
                pop = 0.
            end
            allpops[ii, tt] = pop
            totalpop += pop
        end
    end

    consumption[:population] = allpops
    consumption[:available] = zeros(m.indices_counts[:regions], length(years))

    consumption
end

