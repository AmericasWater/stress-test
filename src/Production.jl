using Mimi
using Distributions

include("world.jl")

@defcomp Production begin
    regions = Index()

    costs_linear = Parameter(index=[regions])
    costs_quadratic = Parameter(index=[regions])
    maximum_capacity = Parameter(index=[regions])
    costs_overproduction = Parameter()

    # Set by optimization
    produced = Parameter(index=[regions, time])

    costs = Variable(index=[regions, time])
end

function timestep(c::Production, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    overproduction = (p.produced[:, tt] - p.maximum_capacity) .* (p.produced[:, tt] .> p.maximum_capacity)
    v.costs = p.costs_linear .* p.produced[:, tt] + p.costs_quadratic .* p.produced[:, tt].^2 + p.costs_overproduction .* overproduction
end

function soleobjective_production(model::Model)
    -sum(model[:Production, :costs]) # minimize cost
end

default_produced() = [100. for i in 1:numcounties*numsteps]

function initproduction(model::Model)
    production = addcomponent(model, Production);

    production[:costs_linear] = convert(Vector{Number}, rand(LogNormal(log(1.0), .1), numcounties));
    production[:costs_quadratic] = convert(Vector{Number}, rand(LogNormal(log(.01), .01), numcounties));
    production[:maximum_capacity] = convert(Vector{Number}, rand(LogNormal(log(1000), 100), numcounties));
    production[:costs_overproduction] = 1000.0

    production
end

function newsoleproduction()
    model = newmodel();

    production = initproduction(model)

    # Default to be overwritten
    production[:produced] = convert(Array{Number, 2}, rand(LogNormal(log(1000), 100), numsteps, numcounties));

    model
end

using OptiMimi

function soleproduction()
    model = newsoleproduction()

    optprob = problem(model, [:Production], [:produced], [0.], [1e6], soleobjective_production);

    solution(optprob, () -> default_produced())
end
