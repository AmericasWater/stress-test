include("Production.jl")
include("mincost.jl")

# At the time Economy is called, we known import prices
# Economy needs to figure how to import and produce to satisfy demand
@defcomp Economy begin
    regions = Index()
    edges = Index()

    importprices = Parameter(index=[edges, time]) # This combines production and transport costs
    link_capacities = Parameter(index=[edges, time])

    # Includes internal and exports
    demand = Parameter(index=[regions, time])

    produced = Variable(index=[regions, time])
    importquantity = Variable(index=[edges, time])
    finalprice = Variable(index=[regions, time])
end

function timestep(c::Economy, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    # Get the supply costs for each potential import
    edge1 = 1
    for rr in 1:numcounties
        numneighbors = out_degree(regverts[names[rr]], regionnet)

        costs = p.importprices[edge1:edge1 + numneighbors - 1, tt]
        capacities = p.link_capacities[edge1:edge1 + numneighbors - 1, tt]

        price2production = (maxprice, maxdemand) -> production_to_price(p_production, rr, tt, maxprice, maxdemand)
        production2price = (production) -> production_cost(p_production, rr, tt, production)

        imported, v.produced[rr, tt], v.finalprice[rr, tt] = mincost_sourcing(p.demand[rr, tt], costs, capacities, production2price, price2production)
        v.importquantity[edge1:edge1 + numneighbors - 1, tt, tt] = imported

        edge1 += numneighbors
    end
end

function initeconomy(model::Model)
    economy = addcomponent(model, Economy);
    production = initproduction(model)

    economy[:importprices] = asmynumeric(rand(LogNormal(log(10), .01), numedges, numsteps), 2);
    economy[:link_capacities] = repeat(MyNumeric[1e6], outer=[numedges, numsteps])
    economy[:demand] = asmynumeric(rand(LogNormal(log(1000), 100), numcounties, numsteps), 2);

    production[:produced] = economy[:produced]

    global p_production = getparams(production)

    economy
end

function newsoleeconomy()
    model = newmodel(1);

    economy = initeconomy(model)

    model
end
