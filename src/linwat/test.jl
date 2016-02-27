include("../world.jl")

include("Consumption.jl")

println("Consumption test...")

m = newmodel(1);
consumption = initconsumption(m, [2000]);
@time run(m)
