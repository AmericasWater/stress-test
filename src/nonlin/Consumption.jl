using Mimi
using Distributions

include("world.jl")

@defcomp Consumption begin
    regions = Index()

    # Utility model is u(q) = d ln(q) - p q
    # At a given price p, optimal q = d / p
    desire = Parameter(index=[regions])
    price = Parameter(index=[regions, time])

    demand = Variable(index=[regions, time])

    marketed = Parameter(index=[regions, time]) # may be > consumed if > demand

    consumed = Variable(index=[regions, time])
    revenue = Variable(index=[regions, time])
end

function timestep(c::Consumption, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    # Old version
    # 1.088635 seconds (620.05 k allocations: 27.871 MB, 1.64% gc time)
    #v.consumed[:, tt] = map(min, p.marketed[:, tt], p.maximum_demand)
    #v.revenue[:, tt] = log(v.consumed[:, tt]) ./ log(p.willingness_base)

    # 0.166657 seconds (67.69 k allocations: 2.066 MB)
    for rr in d.regions
        v.demand[rr, tt] = p.desire[rr] / p.price[rr, tt]
        v.consumed[rr, tt] = min(p.marketed[rr, tt], v.demand[rr])
        v.revenue[rr, tt] = v.consumed[rr, tt] * p.price[rr, tt]
    end
end

function soleobjective_consumption(model::Model)
    sum(model[:Consumption, :revenue]) # maximize revenue
end

default_marketed() = [100. for i in 1:numcounties*numsteps]

function initconsumption(m::Model)
    consumption = addcomponent(m, Consumption)

    consumption[:desire] = asmynumeric(rand(LogNormal(log(100.0), log(10.0)), numcounties));
    consumption[:price] = asmynumeric(rand(LogNormal(log(1000.0), log(100.0)), numcounties, numsteps), 2);

    consumption
end

function newsoleconsumption()
    m = newmodel(1)

    consumption = initconsumption(m)

    # To be set by the optimization
    consumption[:marketed] = asmynumeric(rand(LogNormal(log(500.0), log(100.0)), numcounties, numsteps), );

    m
end

using OptiMimi

function soleconsumption()
    m = newsoleconsumption()

    optprob = problem(m, [:Consumption], [:marketed], [0.], [200.], soleobjective_consumption);

    solution(optprob, () -> default_marketed())
end
