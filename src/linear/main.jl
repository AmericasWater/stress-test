include("../world.jl")

using OptiMimi

include("Production.jl")
include("Transportation.jl")
include("Consumption.jl")
include("Economy.jl")

println("Creating model...")

# First solve entire problem in a single timestep
m = newmodel(1);

# Add all of the components
production = initproduction(m);
transportation = inittransportation(m);
economy = addcomponent(m, Economy);
consumption = initconsumption(m);

# Connect up the components
economy[:produced] = production[:produced];
economy[:regionimports] = transportation[:regionimports];
economy[:regionexports] = transportation[:regionexports];
consumption[:marketed] = economy[:marketed];

# Defaults to be overwritten by optimization
production[:quota] = default_quota(m);
transportation[:imported] = default_imported(m);

# Run it and time it!
@time run(m)

println("Create linear optimization problem...")

# Load the LP Constraints if available
if isfile(joinpath(todata, "networkconstraints$suffix.jld"))
    println("Loading from saved LP Constraints...")
    networkconstraints = deserialize(open(joinpath(todata, "networkconstraints$suffix.jld"), "r"))
else
    println("Creating LP Constraints")

    # Make a network constraint for county rr, time tt
    function makeconstraint(rr, tt)
        # The constraint function
        function constraint(model)
            -model[:Consumption, :surplus][rr, tt]
        end
    end

    # Set up the constraints
    constraints = Function[]
    for tt in 1:m.indices_counts[:time]
        constraints = [constraints; map(rr -> makeconstraint(rr, tt), 1:m.indices_counts[:regions])]
    end

    networkconstraints = savelpconstraints(m, [:Transportation], [:imported], [0., 0.], [1e6, 1e6], soleobjective_transportation, constraints)
    serialize(open(joinpath(todata, "networkconstraints$suffix.jld"), "w"), networkconstraints)
end

# Create the OptiMimi optimization problem
optprob = problem(m, [:Production], [:quota], [0., 0.], [1e6, 1e6], soleobjective_production, Function[], [networkconstraints]);

println("Solving...")
@time sol = solution(optprob)
println(sol)
