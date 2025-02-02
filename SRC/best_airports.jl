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
tif_path = "../DATA/Harmonized_DN_NTL_2020_simVIIRS.tif"

# Open the .tif file using Rasters.jl
dataset = Raster(tif_path)
dataset = resample(dataset, res = 0.05, method = "average")

function agglomoration(airport)
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

airports[!, :agglomoration] = repeat([0.0], nrow(airports))

for row in eachrow(airports)
    row[:agglomoration] = agglomoration(row)
end

CSV.write("../RESULTS/best_airports.csv", airports)

using Plots

latitudes = airports[:, :latitude_deg]
longitudes = airports[:, :longitude_deg]
agglomorations = airports[:, :agglomoration]

# Create the plot
scatter(longitudes, latitudes, markersize=agglomorations, legend=false, xlabel="Longitude", ylabel="Latitude", title="Airports Agglomoration Map")