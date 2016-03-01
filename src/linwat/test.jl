include("../world.jl")

include("Extraction.jl")

println("Extraction test...")

m = newmodel(1);
extraction = initextraction(m, [2000]);
@time run(m)

include("Consumption.jl")

println("Consumption test...")

m = newmodel(1);
consumption = initconsumption(m, [2000]);
@time run(m)
