##Reading citibike data information(CSV file) into a dataframe

bikedf=read.csv("C:/Users/Karpagam/Desktop/Citibikeinfo.csv");

View(bikedf);

##Bike_id is created to store the unique citi bike station IDs
##Extracting the latitude, longitude of bike stations and storing it in the bike dataframe

Bike_id<- bikedf$end.station.id;
lat <- bikedf$end.station.latitude;
long <- bikedf$end.station.longitude;

bike <- data.frame(Bike_id,lat,long);

##Reading the NYC taxi data

taxidf=read.csv("C:/Users/Karpagam/Desktop/tripdata_cleansed/tripdata_cleansed.csv");
View(taxidf);

##Creating the taxi_id by using the seq() function

taxidf$X= seq(1:nrow(taxidf));
taxi_id <-taxidf$X;
taxi_lat <-taxidf$pickup_latitude;
taxi_long <-taxidf$pickup_longitude;

##Extracting the latitude, longitude and the newly created taxi ID and storing it in
##taxich dataframe

taxich <- data.frame(taxi_id,taxi_lat,taxi_long)

##Checking the NYC coordinates and subsetting the taxich dataframe to eliminate longitude in the below range

taxich2 <- subset(taxich, taxich$taxi_long > '-70' & taxich$taxi_long < '-76');


## convert the taxi lat/long coordinates to UTM for the computed zone
##

long2UTM <- function(long) {
  (floor((long + 180)/6) %% 60) + 1
}


## Assuming that all points are within a zone (within 6 degrees in longitude),
## we use the first taxi's longitude to get the zone.

z <- long2UTM(taxich2[1,"taxi_long"])

##Bindings for the Geospatial Data Abstraction Library

library(sp)
install.packages("rgdal");
library(rgdal)

## convert the bike lat/long coordinates to UTM for the computed zone


bike2 <- bike
coordinates(bike2) <- c("long", "lat")
proj4string(bike2) <- CRS("+proj=longlat +datum=WGS84")

bike.xy <- spTransform(bike2, CRS(paste0("+proj=utm +zone=",z," ellps=WGS84")))

## convert the taxi lat/long coordinates to UTM for the computed zone
taxich4 <- taxich2
coordinates(taxich4) <- c("taxi_long", "taxi_lat")
proj4string(taxich4) <- CRS("+proj=longlat +datum=WGS84")

taxich2.xy <- spTransform(taxich4, CRS(paste0("+proj=utm +zone=",z," ellps=WGS84")))

##The RANN package utilizes the Approximate Near Neighbor (ANN) C++ library, 
##which can give the exact near neighbours or (as the name suggests) 
##approximate near neighbours to within a specified error bound.

install.packages("RANN")

library(RANN)

## find the nearest neighbor in bike.xy@coords for each taxi.xy@coords
## The parameter k refers to maximum number of neighbours to compute
## K=1 refers to finding one closest bike station for every taxi ride data

res <- nn2(data=bike.xy@coords, query=taxich2.xy@coords, k=1)

## We can specify to find the nearest neighbor within the specified radius using the 
## below code. This would return all the bike stations that are within .01 km radius of taxi pickup 


## "res" variable is a list stores the result in a list format with two elements
##nn.idx	A N x k integer matrix returning the near neighbour indices.
##nn.dists	A N x k matrix returning the near neighbour Euclidean distances.

##Converting it to dataframe
res1<- as.data.frame(res);
         

View(res1)

## res$nn.dist is a vector of the distance to the nearest bike.xy@coords for each taxi.xy@coords
## res$nn.idx is a vector of indices to bus.xy of the nearest bike.xy@coords for each taxi.xy@coords


## Creating the column "bike_station_ID" in the taxi dataframe to store the closest bikestation ID
## Checking the condition of res to see if the distance is within 1km radius, if not, displaying NA
## we can store n number of neighbours using the below code by changing the id as commented below

taxich2$bike_station_ID <- ifelse(res$nn.dists <= 1000, bike[res1$nn.idx,"Bike_id"], NA)
##taxich$bike_ID_2 <- ifelse(res$nn.dists <= 1000, bike[res1$nn.idx.2,"Bike_id"], NA)
##taxich$bike_ID_3 <- ifelse(res$nn.dists <= 1000, bike[res1$nn.idx.3,"Bike_id"], NA)
##taxich$bike_ID_4 <- ifelse(res$nn.dists <= 1000, bike[res1$nn.idx.4,"Bike_id"], NA)
##taxich$bike_ID_5 <- ifelse(res$nn.dists <= 1000, bike[res1$nn.idx.5,"Bike_id"], NA)


##Creating the column "distance" in the taxi dataframe to store the distance in miles

taxich2$distance <- ifelse(res$nn.dists<=1000, res1$nn.dists*0.00062137119223733 ,NA)


##Voila!

## Writing it back to the file


write.csv(taxich2,"C:/Users/Karpagam/Desktop/Taxiwithbike_nearestneighbours.csv")


