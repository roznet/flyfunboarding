<?php

class Ticket {
    public Passenger $passenger;
    public Flight $flight;
    public string $seatNumber;
    // this is calculated from the flight and passenger
    public string $ticketNumber;

    public function __construct(Passenger $passenger, Flight $flight, string $seatNumber, string $ticketNumber = null) {
        $this->passenger = $passenger;
        $this->flight = $flight;
        $this->seatNumber = $seatNumber;
        if ($ticketNumber === null) {
            $this->ticketNumber = $flight->uniqueFlightIdentifier() . $passenger->uniqueIdentifer();
        }else{
            $this->ticketNumber = $ticketNumber;
        }
    }

    public function toJson() : array {
        return [
            'passenger' => $this->passenger->toJson(),
            'flight' => $this->flight->toJson(),
            'seatNumber' => $this->seatNumber,
            'ticketNumber' => $this->ticketNumber
        ];
    }

    static public function fromJson(array $json) : Ticket {
        if (isset($json['ticketNumber'])) {
            return new Ticket(
                Passenger::fromJson($json['passenger']),
                Flight::fromJson($json['flight']),
                $json['seatNumber'],
                $json['ticketNumber']
            );
        }else{
            return new Ticket(
                Passenger::fromJson($json['passenger']),
                Flight::fromJson($json['flight']),
                $json['seatNumber']
            );
        }
    }
}
