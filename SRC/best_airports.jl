using Rasters
using Distances
import ArchGDAL
using DimensionalData
using CSV
using DataFrames

url = "https://davidmegginson.github.io/ourairports-data/airports.csv"
airports = CSV.read(download(url), DataFrame)
airports = filter(row -> row.type == "large_airport", airports)
# Define the path to the .tif file
ntl_path = "../DATA/Harmonized_DN_NTL_2020_simVIIRS.tif"

# Open the .tif file using Rasters.jl
ntl = Raster(ntl_path)
ntl = resample(ntl, res = 0.05, method = "average")

bv_path = "../DATA/GHS_BUILT_V_E2025_GLOBE_R2023A_4326_30ss_V1_0.tif"
bv = Raster(bv_path)
bv = resample(bv, res = 0.05, method = "average")

function agglomeration(airport, dataset)
    airport_coords = (airport["latitude_deg"], airport["longitude_deg"])
    distances = Array{Union{Float64, Missing}}(undef, size(dataset, 1), size(dataset, 2))
    for row in 1:size(dataset, 2)
        for col in 1:size(dataset, 1)
            if dataset[col, row] < 0.1
                continue
            end
            pixel_coords = (dims(dataset, 2)[row], dims(dataset, 1)[col])
            distance = haversine(airport_coords, pixel_coords)
            distances[col, row] = distance
        end
    end
    sum(skipmissing(dataset .* (1 ./ distances))) / sum(skipmissing(1 ./ distances))
end

airports[!, :ntl_agglomeration] = repeat([0.0], nrow(airports))
airports[!, :bv_agglomeration] = repeat([0.0], nrow(airports))


for row in eachrow(airports)
    row[:ntl_agglomeration] = agglomeration(row, ntl)
end

for row in eachrow(airports)
    row[:bv_agglomeration] = agglomeration(row, bv)
end


airports = select(airports, [:id, :ident, :type, :name, :latitude_deg, :longitude_deg, :iso_country, :iso_region, :municipality, :ntl_agglomeration, :bv_agglomeration])


CSV.write("../RESULTS/best_airports.csv", airports)
using ExcelFiles
for col in names(airports)
    if eltype(airports[!, col]) <: AbstractString
        airports[!, col] = String.(airports[!, col])
    end
end

save("../RESULTS/best_airports.xlsx", airports)