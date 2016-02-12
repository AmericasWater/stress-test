using Mimi
using Distributions

@defcomp LinearProduction begin
    regions = Index()

    # Internal
    costs_linear = Parameter(index=[regions])

    # Set by optimization
    quota = Parameter(index=[regions, time])

    produced = Variable(index=[regions, time]) # copy of quota
    costs = Variable(index=[regions, time])
end

function timestep(c::LinearProduction, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        v.produced[rr, tt] = p.quota[rr, tt]
        v.costs[rr, tt] = v.produced[rr, tt] * p.costs_linear[rr]
    end
end

function soleobjective_production(model::Model)
    sum(model[:LinearProduction, :costs]) # minimize cost
end

function initproduction(model::Model)
    production = addcomponent(model, LinearProduction);

    production[:costs_linear] = asmynumeric(rand(LogNormal(log(1.0), .1), numcounties));

    production
end

default_quota() = [100. for i in 1:numcounties*numsteps]
