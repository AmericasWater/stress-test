using Mimi
using Distributions
using Devectorize

include("world.jl")

@defcomp Production begin
    regions = Index()

    costs_positive = Parameter(index=[regions])
    costs_linear = Parameter(index=[regions])
    costs_quadratic = Parameter(index=[regions])
    costs_overproduction = Parameter()
    maximum_capacity = Parameter(index=[regions])

    # Set by optimization
    quota = Parameter(index=[regions, time])

    produced = Variable(index=[regions, time])
    costs = Variable(index=[regions, time])
end

function production_cost{T<:Real}(p::ProductionParameters, rr::Int, tt::Int, produced::T)
    if produced == 0
        return 0
    else
        if produced > p.maximum_capacity[rr]
            overproduction = produced - p.maximum_capacity[rr]
            produced = produced - overproduction
        else
            overproduction = 0
        end
        return p.costs_positive[rr] + p.costs_linear[rr] .* produced + p.costs_quadratic[rr] .* produced^2 + overproduction * p.costs_overproduction
    end
end

function production_to_price{T<:Real}(p::ProductionParameters, rr::Int, tt::Int, price::T, maxprod::T)
    if price < p.costs_positive[rr]
        return 0
    else
        # price = (p.costs_positive[rr] + p.costs_linear[rr] .* produced + p.costs_quadratic[rr] .* produced^2) / produced
        a = p.costs_positive[rr]
        b = p.costs_linear[rr] - price
        c = p.costs_quadratic[rr]
        produced = (-b + sqrt(b^2 - 4*a*c)) / 2a
        if produced > maxprod
            produced = maxprod
        end
    end
end

function timestep(c::Production, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    # Old version
    # 1.465048 seconds (818.18 k allocations: 36.493 MB, 2.54% gc time)
    #overproduction = (p.produced[:, tt] - p.maximum_capacity) .* (p.produced[:, tt] .> p.maximum_capacity)
    #v.costs[:, tt] = p.costs_linear .* p.produced[:, tt] + p.costs_quadratic .* p.produced[:, tt].^2 + p.costs_overproduction .* overproduction

    # 0.126028 seconds (66.72 k allocations: 2.134 MB)
    for rr in d.regions
        v.produced[rr, tt] = p.quota[rr, tt] # assume I can always do it
        v.costs[rr, tt] = production_cost(p, rr, tt, p.quota[rr, tt])
    end
end

function soleobjective_production(model::Model)
    -sum(model[:Production, :costs]) # minimize cost
end

default_quota() = [100. for i in 1:numcounties*numsteps]

function initproduction(model::Model)
    production = addcomponent(model, Production);

    production[:costs_positive] = asmynumeric(rand(LogNormal(log(1000), .1), numcounties));
    production[:costs_linear] = asmynumeric(rand(LogNormal(log(1.0), .1), numcounties));
    production[:costs_quadratic] = asmynumeric(rand(LogNormal(log(.01), .01), numcounties));
    production[:maximum_capacity] = asmynumeric(rand(LogNormal(log(1000), 100), numcounties));
    production[:costs_overproduction] = 1000.0

    production
end

function newsoleproduction()
    model = newmodel(1);

    production = initproduction(model)

    # Default to be overwritten
    production[:quota] = asmynumeric(rand(LogNormal(log(1000), 100), numcounties, numsteps), 2);

    model
end

using OptiMimi

function soleproduction()
    model = newsoleproduction()

    optprob = problem(model, [:Production], [:quota], [0.], [1e6], soleobjective_production);

    solution(optprob, () -> default_produced())
end
