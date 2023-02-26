<?php

require_once( '../php/autoload.php' );

$sample_aircraft_json = '{
    "registration": "N122DR",
    "type": "Cirrus SR22T"
}';

$sample_flight_json = '{
    "origin": "EGTF",
    "destination": "LFQA",
    "gate": "1",
    "flightNumber": "N122DR",
    "aircraft": {
    "registration": "N122DR",
    "type": "Cirrus SR22T"
    },
    "scheduledDepartureDate": "2021-06-01 12:00:00",
    "flightTime": "PT1H30M"
}';

$sample_flight_json = '{
    "origin": "EGTF",
    "destination": "EBOS",
    "gate": "1",
    "flightNumber": "N122DR",
    "aircraft": {
    "registration": "N122DR",
    "type": "Cirrus SR22T"
    },
    "scheduledDepartureDate": "2023-05-06 09:00:00",
    "flightTime": "PT1H00M"
}';
$sample_passenger_json = '{
    "firstName": "John",
    "lastName": "Doe",
    "middleName": "M",
    "formattedName": "Mr. John M Doe"
}';

$sample_ticket_json = '{
    "seatNumber": "1A",
    "passenger": {
        "firstName": "John",
        "lastName": "Doe",
        "middleName": "M",
        "formattedName": "Mr. John M Doe"
    },
    "flight": {
        "origin": "EGTF",
        "destination": "EBOS",
        "gate": "1",
        "flightNumber": "N122DR",
        "aircraft": {
            "registration": "N122DR",
            "type": "Cirrus SR22T"
        },
        "scheduledDepartureDate": "2023-05-06 09:00:00",
        "flightTime": "PT1H00M"
    }
}';

$sample_aircraft = Aircraft::fromJson(json_decode($sample_aircraft_json, true));
$sample_flight = Flight::fromJson(json_decode($sample_flight_json, true));
$sample_passenger = Passenger::fromJson(json_decode($sample_passenger_json, true));
$sample_ticket = Ticket::fromJson(json_decode($sample_ticket_json, true));

function writeToFile($filename, $content) {
    $file = fopen($filename, 'w');
    // json encode pretty content
    $json = json_encode($content, JSON_PRETTY_PRINT);
    fwrite($file, $json);
    fclose($file);
}
// Save sample_aircraft to a file
//writeToFile('../samples/sample_aircraft.json', $sample_aircraft->toJson());
//writeToFile('../samples/sample_flight.json', $sample_flight->toJson());
//writeToFile('../samples/sample_passenger.json', $sample_passenger->toJson());
//writeToFile('../samples/sample_ticket.json', $sample_ticket->toJson());
