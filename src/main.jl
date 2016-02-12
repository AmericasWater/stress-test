using OptiMimi

include("Production.jl")
include("Transportation.jl")
include("Consumption.jl")
include("Economy.jl")

# First solve entire problem in a single timestep to get prices
m = newmodel(1);

production = initproduction(m);
transportation = inittransportation(m);
consumption = initconsumption(m);
economy = addcomponent(m, Economy);

economy[:producedcost] = production[:costs];
economy[:produced] = production[:produced];
economy[:balance] = transportation[:balance];
economy[:realimports] = transportation[:realimports];
economy[:transportspending] = transportation[:transportspending];
economy[:costs_overproduction] = 1000.0

consumption[:price] = economy[:finalprice];
consumption[:marketed] = economy[:marketed];

# Defaults to be overwritten by optimization
production[:quota] = asmynumeric(rand(LogNormal(log(1000), 100), numcounties, numsteps), 2);
transportation[:imported] = asmynumeric(rand(LogNormal(log(1000), 100), numedges, numsteps), 2);

@time run(m)

function objective(model::Model)
    soleobjective_production(model) + soleobjective_transportation(model) + soleobjective_consumption(model)
end

optprob = problem(m, [:Production, :Transportation], [:quota, :imported], [0., 0.], [1e6, 1e6], objective);

sol = solution(optprob, () -> [default_produced(); default_exported()])

# Determine the price on each link
