setwd("~/projects/water/model/stress-test/src/linwat/")

source("~/projects/research-common/R/drawmap.R")

counties <- read.csv("results/counties.csv")
counties$name <- NA
for (ii in 1:nrow(counties)) {
    jj <- which(county.fips$fips == counties$fips[ii])
    if (length(jj) == 1)
        counties$name[ii] <- as.character(county.fips$polyname[jj])
}

drawusa <- function(values, style="quantile") {
    colors <- rev(brewer.pal(9, "RdYlGn"))

    brks <- classIntervals(values, n=9, style=style)
    brks <- brks$brks

    map("state", fill=T, mar=c(1, 2, 3, 0))
    for (ii in 1:length(values)) {
        if (!is.na(counties$name[ii]))
            map("county", counties$name[ii], col=colors[findInterval(values[ii], brks, all.inside=TRUE)], fill=T, mar=c(1, 2, 3, 0), add=T)
    }

    legend("bottomleft", legend=leglabs(round(brks, digits=3)), fill=colors, bty="n", cex=.7)
}

pdf("results/demand-allotment.pdf", width=10, height=6)
drawusa(counties$demand / counties$allotment)
dev.off()

pdf("results/pumping.pdf", width=10, height=6)
drawusa(counties$pumping / 1e9)
dev.off()

pdf("results/exports-imports.pdf", width=10, height=6)
drawusa((counties$exports - counties$imports) / 1e9, style="equal")
dev.off()

pdf("results/imports.pdf", width=10, height=6)
drawusa(counties$imports / 1e9, style="equal")
dev.off()
