<?php

class Flight {
    public Airport $origin;
    public Airport $destination;
    public string $gate;
    public string $flightNumber;
    public Aircraft $aircraft;
    public array $stats = [];
    public DateTime $scheduledDepartureDate;
    public int $flight_id = -1;
    public int $aircraft_id = -1;
    public ?string $flight_identifier = null;

    public static $jsonKeys = [
        'origin' => 'Airport',
        'destination' => 'Airport',
        'gate' => 'string',
        'flightNumber'  => 'string',
        'stats' => 'array<Stats>',
        'aircraft' => 'Aircraft',
        'scheduledDepartureDate' => 'DateTime',
        'flight_id' => 'integer',
        'flight_identifier' => 'string'
    ];
    public static $jsonValuesOptionalDefaults = [
        'flight_id' => -1,
        'flight_identifier' => '',
        'stats' => []
    ];

    public static function fromJson($json) : Flight {
        $rv = JsonHelper::fromJson($json, 'Flight');
        if(isset($rv->aircraft->aircraft_id)) {
            $rv->aircraft_id = $rv->aircraft->aircraft_id;
        }
        return $rv;
    }

    public function hasFlightNumber() : bool {
        return !is_null($this->flightNumber) && $this->flightNumber != '' && $this->flightNumber != $this->aircraft->registration;
    }

    public function formatScheduledDepartureDate() : string {
        $dateToDisplay = $this->scheduledDepartureDate;
        if( $this->origin->timezone_identifier) {
            $tz = new DateTimeZone($this->origin->timezone_identifier);
            $dateToDisplay->setTimezone($tz);
        }
        return $dateToDisplay->format('D M d, H:i');
    }
    

    public function toJson() : array {
        return JsonHelper::toJson($this);
    }
}
