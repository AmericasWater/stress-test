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
extraction = initextraction(m, [2000]);
transportation = inittransportation(m);
infrastructure = addcomponent(m, Infrastructure);
consumption = initconsumption(m, [2000]);

# Connect up the components
infrastructure[:extracted] = extraction[:extracted];
infrastructure[:regionimports] = transportation[:regionimports];
infrastructure[:regionexports] = transportation[:regionexports];
consumption[:available] = infrastructure[:available];

# Run it and time it!
@time run(m)

println("Testing:")
println(m[:Consumption, :surplus][1, 1])

println("Create linear optimization problem...")
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

# Combine component-specific objectives
function objective(model::Model)
    soleobjective_extraction(model) + soleobjective_transportation(model)
end

# Create the OptiMimi optimization problem
optprob = problem(m, [:Extraction, :Transportation], [:pumping, :imported], [0., 0.], [Inf, Inf], objective, constraints=constraints, algorithm=:GUROBI_LINPROG);

println("Solving...")
@time sol = solution(optprob)
println(sol)

setparameters(m, [:Extraction, :Transportation], [:pumping, :imported], sol)
@time run(m)

df = DataFrame(fips=m.indices_values[:regions], demand=vec(m[:Consumption, :demand]),
               allotment=vec(m.components[:Extraction].Parameters.free_allotment),
               pumping=vec(m.components[:Extraction].Parameters.pumping),
               imports=vec(m[:Transportation, :regionimports]),
               exports=vec(m[:Transportation, :regionexports]))
writetable("results/counties$suffix.csv", df)


