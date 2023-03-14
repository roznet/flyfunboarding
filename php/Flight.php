<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public DateTime $scheduledDepartureDate;
    public DateInterval $flightTime; 
    public int $flight_id = -1;
    public int $aircraft_id = -1;


    function identifierTag() : string {
        // EGTFLFMD.N122DR.202012311200
        return $this->origin->icao . $this->destination->icao . '.' . $this->aircraft->registration . '.' . $this->scheduledDepartureDate->format('YmdHi');
    }
    function uniqueIdentifier() : array {
        return [ 'flight_identifier' => MyFlyFunDb::uniqueIdentifier($this->identifierTag()) ];
    }

    public static $jsonKeys = [
        'origin' => 'Airport',
        'destination' => 'Airport',
        'gate' => 'string',
        'flightNumber'  => 'string',
        'aircraft' => 'Aircraft',
        'scheduledDepartureDate' => 'DateTime',
        'flightTime' => 'DateInterval',
        'flight_id' => 'integer',
    ];
    public static $jsonValuesOptionalDefaults = [
        'flight_id' => -1,
    ];

    public static function fromJson($json) : Flight {
        return JsonHelper::fromJson($json, 'Flight');
    }

    public function toJson() : array {
        return JsonHelper::toJson($this);
    }
}
