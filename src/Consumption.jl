using Mimi
using Distributions

include("world.jl")

@defcomp Consumption begin
    regions = Index()

    willingness_base = Parameter(index=[regions])
    maximum_need = Parameter(index=[regions])

    marketed = Parameter(index=[regions, time]) # may be > consumed if > maximum_need

    consumed = Variable(index=[regions, time])
    revenue = Variable(index=[regions, time])
end

function timestep(c::Consumption, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    v.consumed[:, tt] = map(min, p.marketed[:, tt], p.maximum_need)
    v.revenue[:, tt] = log(v.consumed[:, tt]) ./ log(p.willingness_base)
end

function soleobjective_consumption(model::Model)
    sum(model[:Consumption, :revenue]) # maximize revenue
end

default_marketed() = [100. for i in 1:numcounties*numsteps]

function initconsumption(m::Model)
    consumption = addcomponent(m, Consumption)

    consumption[:willingness_base] = convert(Vector{Number}, rand(LogNormal(log(100.0), log(10.0)), numcounties));
    consumption[:maximum_need] = convert(Vector{Number}, rand(LogNormal(log(1000.0), log(100.0)), numcounties));

    consumption
end

function newsoleconsumption()
    m = newmodel()

    consumption = initconsumption(m)

    # To be set by the optimization
    consumption[:marketed] = convert(Array{Number, 2}, rand(LogNormal(log(500.0), log(100.0)), numsteps, numcounties));

    m
end

using OptiMimi

function soleconsumption()
    m = newsoleconsumption()

    optprob = problem(m, [:Consumption], [:marketed], [0.], [1e6], soleobjective_consumption);

    solution(optprob, () -> default_marketed())
end
