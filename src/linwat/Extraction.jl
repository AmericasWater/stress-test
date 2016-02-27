# The extraction component
#
# Each region has the ability to produce the resource.  It will do so under a
# linear cost structure, and at the level set by `pumping`.

using Mimi
using Distributions

@defcomp Extraction begin
    regions = Index()

    # Internal
    # The cost per unit of resource
    cost_linear = Parameter(index=[regions])

    # Set by optimization
    # The amount to produce
    pumping = Parameter(index=[regions, time])

    # The amount extracted: a copy of pumping
    extracted = Variable(index=[regions, time])
    # The cost to produce it
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
        v.extracted[rr, tt] = p.pumping[rr, tt]
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
function initextraction(model::Model)
    extraction = addcomponent(model, Extraction);

    # Use random extraction costs, from a LogNormal distribution
    extraction[:cost_linear] = TODO

    extraction
end

"Default pumping is small and positive"
default_pumping(m::Model) = TODO

