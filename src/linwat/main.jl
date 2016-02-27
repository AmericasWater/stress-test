include("../world.jl")

using OptiMimi

include("Extraction.jl")
include("Transportation.jl")
include("Consumption.jl")
include("Infrastructure.jl")

println("Creating model...")

# First solve entire problem in a single timestep
m = newmodel(1);

# Add all of the components
extraction = initextraction(m);
transportation = inittransportation(m);
infrastructure = addcomponent(m, Infrastructure);
consumption = initconsumption(m);

# Connect up the components
infrastructure[:extracted] = extraction[:extracted];
infrastructure[:regionimports] = transportation[:regionimports];
infrastructure[:regionexports] = transportation[:regionexports];
consumption[:available] = infrastructure[:available];

# Defaults to be overwritten by optimization
extraction[:quota] = default_quota(m);
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

    networkconstraints = savelpconstraints(m, [:Transportation], [:imported], constraints)
    serialize(open(joinpath(todata, "networkconstraints$suffix.jld"), "w"), networkconstraints)
end

# Combine component-specific objectives
function objective(model::Model)
    soleobjective_extraction(model) + soleobjective_transportation(model)
end

# Create the OptiMimi optimization problem
optprob = problem(m, [:Extraction], [:quota], [0., 0.], [1e6, 1e6], objective, Function[], [networkconstraints]);

println("Solving...")
@time sol = solution(optprob, (m::Model) -> [vec(default_quota(m)); vec(default_imported(m))])
println(sol)
