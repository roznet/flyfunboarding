<?php

$sample_aircraft_json = '{
    "registration": "N122DR",
    "type": "Cirrus SR22T"
}';

$sample_flight_json = '{
    "origin": "EGTF",
    "destination": "LFMD",
    "gate": "1",
    "flightNumber": "N122DR",
    "aircraft": {
    "registration": "N122DR",
    "type": "Cirrus SR22T"
    },
    "date": "2021-06-01 12:00:00",
    "flightTime": "PT1H30M"
}';

$sample_passenger_json = '{
    "firstName": "Brice",
    "lastName": "Rosenzweig",
    "middleName": "M",
    "formattedName": "Mr. Brice M Rosenzweig"
}';

$sample_aircraft = Aircraft::fromJson(json_decode($sample_aircraft_json, true));
$sample_flight = Flight::fromJson(json_decode($sample_flight_json, true));
$sample_passenger = Passenger::fromJson(json_decode($sample_passenger_json, true));
?>

