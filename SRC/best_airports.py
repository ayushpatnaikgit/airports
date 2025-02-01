import rasterio
import airportsdata
from geopy.distance import geodesic


airports = airportsdata.load()

# Define the path to the .tif file
tif_path = '../DATA/Harmonized_DN_NTL_2020_simVIIRS.tif'

ntl = rasterio.open(tif_path)

delhi_airport = airports['VIDP']
delhi_airport_lat = delhi_airport['lat']
delhi_airport_lon = delhi_airport['lon']
delhi_airport_coords = (delhi_airport_lat, delhi_airport_lon)


distances = [[0 for _ in range(ntl.width)] for _ in range(ntl.height)]

# Calculate the distance from delhi_airport for each pixel
for row in range(ntl.height):
    for col in range(ntl.width):
        # Get the coordinates of the pixel
        pixel_coords = ntl.xy(row, col)
        print("Pixel coordinates:", pixel_coords)
        # Calculate the distance to delhi_airport
        distance = geodesic(delhi_airport_coords, pixel_coords).kilometers
        ntl[row][col] = distance

print("NTL distances matrix:", ntl)