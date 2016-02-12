# Economy is just an accounting mechanism
@defcomp Economy begin
    regions = Index()

    producedcost = Parameter(index=[region, time])
    costs_overproduction = Parameter()

    produced = Parameter(index=[regions, time])
    balance = Parameter(index=[regions, time])

    realimports = Parameter(index=[edges, time])
    transportspending = Parameter(index=[edges, time])

    finalprice = Variable(index=[regions, time])
    marketed = Variable(index=[regions, time])
end

function timestep(c::Economy, tt::Int)
    v = c.Variables
    p = c.Parameters
    d = c.Dimensions

    # Initial guess of finalprice
    for rr in d.regions
        v.marketed[rr, tt] = p.produced[rr, tt] + p.balance[rr, tt]
        if v.marketed[rr, tt] < 0
            # Force additional production
            productionspent = p.producedcost[rr, tt] * p.produced[rr, tt] + p.costs_overproduction * -v.marketed[rr, tt]
            v.finalprice[rr, tt] = productionspent / (p.produced[rr, tt] - v.marketed[rr, tt])
        else
            v.finalprice[rr, tt] = p.producedcost[rr, tt]
        end
    end
    difference = true

    while difference
        difference = false
        edge1 = 1
        for rr in d.regions
            numneighbors = out_degree(regverts[names[rr]], regionnet)

            sources = get(sourceiis, rr, Int64[])
            for source in sources
                if p.realimports[edge1] > 0
                    importprice = v.finalprice[source, tt] + p.transportspending[edge1, tt] / p.realimports[edge1, tt]
                    if importprice > v.finalprice[rr, tt]
                        v.finalprice[rr, tt] = importprice
                        difference = true
                    end
                end
                edge1 += 1 # length(sources) == numneighbors
            end
        end
    end
end

function constraint(c::Economy, tt::Int)
    -c.Variables.balance # not totally necessary, because of additional production forcing above
end
