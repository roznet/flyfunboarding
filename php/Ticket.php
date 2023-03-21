<?php

class Ticket {
    public Passenger $passenger;
    public Flight $flight;
    public string $seatNumber;
    // this is calculated from the flight and passenger
    public int $ticket_id = -1;
    public int $flight_id = -1;
    public int $passenger_id = -1;
    public ?string $ticket_identifier = null;

    static public function issue(Passenger $passenger, Flight $flight, string $seatNumber, int $ticket_id = -1) : Ticket {
        $ticket = new Ticket();
        $ticket->passenger = $passenger;
        $ticket->flight = $flight;
        $ticket->seatNumber = $seatNumber;
        $ticket->ticket_id = $ticket_id;
        return $ticket;
    }

    static $jsonKeys = [
        'passenger' => 'Passenger',
        'flight' => 'Flight',
        'seatNumber' => 'string',
        'ticket_id' => 'integer',
        'flight_id' => 'integer',
        'passenger_id' => 'integer',
        'ticket_identifier' => 'string'

    ];
    static $jsonValuesOptionalDefaults = [
        'ticket_id' => -1,
        'flight_id' => -1,
        'passenger_id' => -1,
        'ticket_identifier' => ''
    ];
    public function toJson() : array {
        return JsonHelper::toJson($this);
    }

    static public function fromJson(array $json) : Ticket {
        $rv = JsonHelper::fromJson($json, 'Ticket');
        if(isset($rv->passenger->passenger_id)) {
            $rv->passenger_id = $rv->passenger->passenger_id;
        }
        if(isset($rv->flight->flight_id)) {
            $rv->flight_id = $rv->flight->flight_id;
        }

        return $rv;
    }
}
