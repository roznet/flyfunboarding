<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public DateTime $date;
    public DateInterval $flightTime; 

    // Example json object:
    // {
    //    "origin": "EGTF",
    //    "destination": "LFMD",
    //    "gate": "1",
    //  "flightNumber": "N122DR",
    //  "aircraft": {
    //  "registration": "N122DR",
    //  "type": "Cessna 172"
    //  },

    // create from json
    public static function fromJson($json) : Flight {
        $flight = new Flight();
        $flight->origin = new Airport($json['origin']);
        $flight->destination = new Airport($json['destination']);
        $flight->gate = $json['gate'];
        $flight->flightNumber = $json['flightNumber'];
        $flight->aircraft = Aircraft::fromJson($json['aircraft']);
        $flight->date = new DateTime($json['date']);
        $flight->flightTime = new DateInterval($json['flightTime']);
        return $flight;
    }
}
?>
