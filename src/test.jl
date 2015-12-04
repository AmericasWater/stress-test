include("Transportation.jl")

println("Transportation test...")
m = newsoletransportation();
@time run(m)

println("Transportation optimization...")
@time sol = soletransportation();
println(sol)

include("Consumption.jl")

println("Consumption test...")
m = newsoleconsumption();
@time run(m)

println("Consumption optimization...")
@time sol = soleconsumption();
println(sol)

include("Production.jl")

println("Production test...")
m = newsoleproduction();
@time run(m)

println("Production optimization...")
@time sol = soleproduction();
println(sol)
