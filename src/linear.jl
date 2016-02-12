using OptiMimi

include("world.jl")

include("LinearProduction.jl")
include("LinearTransportation.jl")
include("LinearConsumption.jl")
include("LinearEconomy.jl")

# First solve entire problem in a single timestep to get prices
m = newmodel(1);

production = initproduction(m);
transportation = inittransportation(m);
economy = addcomponent(m, LinearEconomy);
consumption = initconsumption(m);

economy[:produced] = production[:produced];
economy[:regionimports] = transportation[:regionimports];
economy[:regionexports] = transportation[:regionexports];
consumption[:marketed] = economy[:marketed];

# Defaults to be overwritten by optimization
production[:quota] = asmynumeric(rand(LogNormal(log(1000), 100), numcounties, numsteps), 2);
transportation[:imported] = asmynumeric(rand(LogNormal(log(1000), 100), numedges, numsteps), 2);

@time run(m)

function objective(model::Model)
    soleobjective_production(model) + soleobjective_transportation(model)
end

func = unaryobjective(m, [:LinearProduction, :LinearTransportation], [:quota, :imported], objective)
init = () -> [default_quota(); default_imported()]
@time func(init())

println("Create constraints...")
# Make a network constraint for county rr, time tt
function makeconstraint(rr, tt)
    # The constraint function
    function constraint(model)
        -model[:LinearConsumption, :surplus][rr, tt]
    end
end

# Set up the constraints
constraints = Function[]
for tt in 1:numsteps
    constraints = [constraints; map(rr -> makeconstraint(rr, tt), 1:numcounties)]
end

optprob = problem(m, [:LinearProduction, :LinearTransportation], [:quota, :imported], [0., 0.], [1e6, 1e6], objective, constraints=constraints, algorithm=:GUROBI_LINPROG);

println("Solving...")
@time sol = solution(optprob, () -> [default_quota(); default_imported()])
println(sol)
