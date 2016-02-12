using Mimi
using Distributions

@defcomp LinearConsumption begin
    regions = Index()

    # Internal
    demand = Parameter(index=[regions, time])

    # External
    marketed = Parameter(index=[regions, time])

    surplus = Variable(index=[regions, time])
end

function timestep(c::LinearConsumption, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    for rr in d.regions
        v.surplus[rr, tt] = p.marketed[rr, tt] - p.demand[rr, tt]
    end
end

function initconsumption(m::Model)
    consumption = addcomponent(m, LinearConsumption)

    consumption[:demand] = repeat(asmynumeric(rand(LogNormal(log(1000.0), log(10.0)), numcounties)), outer=[1, numsteps]);

    consumption
end
