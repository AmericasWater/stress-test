using OptiMimi

include("Production.jl")
include("Transportation.jl")
include("Consumption.jl")

m = newmodel()

production = initproduction(m)
transportation = inittransportation(m)
consumption = initconsumption()

transportation[:produced] = production[:produced]
consumption[:marketed] = transportation[:marketed]

# Defaults to be overwritten by optimization
production[:produced] = convert(Array{Number, 2}, rand(LogNormal(log(1000), 100), numsteps, numcounties));
transportation[:exported] = convert(Array{Number, 2}, rand(LogNormal(log(1000), 100), numedges, numsteps))

function objective(model::Model)
    soleobjective_production() + soleobjective_transportation() + soleobjective_consumption()
end

optprob = problem(m, [:Production, :Transportation], [:produced, :exported], [0. 0.], [1e6 1e6], objective);

solution(optprob, () -> default_produced() + default_exported() + default_marketed()
