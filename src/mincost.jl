function mincost_sourcing(demand, importprice, importcapacities, production2price, price2production)
    if length(importprice) == 0
        return [], demand, production2price(demand)
    end

    order = sortperm(importprice)
    imported = zeros(length(importprice))
    produced = 0

    # Start with some production; 0 if importprice_positive > importprice[order[1]]
    produced = price2production(importprice[order[1]], demand)
    if produced >= demand
        return imported, produced, production2price(demand)
    end

    importsupply = 0
    for ii in 1:length(order)
        # Import up to demand or capacity
        imported[order[ii]] = min(demand - importsupply - produced, importcapacities[order[ii]])
        if imported[order[ii]] <= importcapacities[order[ii]]
            return imported, produced, importprice[order[ii]]
        end

        importsupply += imported[order[ii]]

        # Produce up to next price or capacity
        if ii == length(order)
            produced = demand - importsupply
            return imported, produced, production2price(produced)
        else
            produced = price2production(importprice[ii+1], demand - importsupply)
            if demand <= produced + importsupply
                return imported, produced, production2price(produced)
            end
        end
    end
end

