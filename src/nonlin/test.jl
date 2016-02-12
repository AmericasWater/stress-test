include("Transportation.jl")

println("Transportation test...")
m = newsoletransportation();
@time run(m)

println("Transportation optimization...")
@time sol = soletransportation(); # 15 minutes
println(sol)

include("Consumption.jl")

println("Consumption test...")
m = newsoleconsumption();
@time run(m)

println("Consumption optimization...")
@time sol = soleconsumption(); # 1 second
println(sol)

include("Production.jl")

println("Production test...")
m = newsoleproduction();
@time run(m)

println("Production optimization...")
@time sol = soleproduction();
println(sol)

include("Economy.jl")

println("Economy test...")
m = newsoleeconomy();
@time run(m)

println("Economy optimization...")
@time sol = soleeconomy();
println(sol)
