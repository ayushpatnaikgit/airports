using Rasters
using Distances
using PyCall
import ArchGDAL
using DimensionalData

# Load the airports data using PyCall
airports = pyimport("airportsdata").load()

# Define the path to the .tif file
tif_path = "../DATA/Harmonized_DN_NTL_2020_simVIIRS.tif"

# Extract latitude and longitude from delhi_airport
delhi_airport = airports["VIDP"]
delhi_airport_lat = delhi_airport["lat"]
delhi_airport_lon = delhi_airport["lon"]
delhi_airport_coords = (delhi_airport_lat, delhi_airport_lon)

# Open the .tif file using Rasters.jl
dataset = Raster(tif_path)

# Initialize the ntl matrix with the same dimensions as the dataset
distances = Array{Union{Float64, Missing}}(undef, size(dataset, 1), size(dataset, 2))
# Calculate the distance from delhi_airport for each pixel
for row in 1:size(dataset, 2)
    for col in 1:size(dataset, 1)
        # Get the coordinates of the pixel
        if dataset[col, row] < 0.1
            distances[col, row] = missing
            continue
        end
        pixel_coords = (dims(dataset, 2)[row], dims(dataset, 1)[col])
        # Calculate the distance to delhi_airport using haversine formula
        distance = haversine(delhi_airport_coords, pixel_coords)
        distances[col, row] = distance
    end
end

sum(skipmmissing(dataset .* 1./distances)) / sum(skipmmissing(1./distances))