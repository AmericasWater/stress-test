# The production component
#
# Each region has the ability to produce the resource.  It will do so under a
# linear cost structure, and at the level set by `quota`.

using Mimi
using Distributions

@defcomp Production begin
    regions = Index()

    # Internal
    # The cost per unit of resource
    cost_linear = Parameter(index=[regions])

    # Set by optimization
    # The amount to produce
    quota = Parameter(index=[regions, time])

    # The amount produced: a copy of quota
    produced = Variable(index=[regions, time])
    # The cost to produce it
    cost = Variable(index=[regions, time])
end

"""
Compute the amount produced and the cost for doing it.
"""
function timestep(c::Production, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        # Production is a copy of quota
        v.produced[rr, tt] = p.quota[rr, tt]
        # Total cost is production * cost-per-unit
        v.cost[rr, tt] = v.produced[rr, tt] * p.cost_linear[rr]
    end
end

"""
The objective of the production component is to minimize production costs.
"""
function soleobjective_production(model::Model)
    sum(model[:Production, :cost])
end

"""
Add a production component to the model.
"""
function initproduction(model::Model)
    production = addcomponent(model, Production);

    # Use random production costs, from a LogNormal distribution
    production[:cost_linear] = asmynumeric(rand(LogNormal(log(1.0), .1), m.indices_counts[:regions]));

    production
end

"Default quota is small and positive"
default_quota(m::Model) = asmynumeric(ones(m.indices_counts[:regions], m.indices_counts[:time]))

