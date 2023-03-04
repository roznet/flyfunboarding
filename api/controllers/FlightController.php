<?php

class FlightController extends Controller
{
    public function create() {
        $this->validateMethod('POST');

        $json = $this->getJsonPostBody();
        if (!isset($json['aircraft']['aircraft_id'])) {
            $this->terminate(400, 'Missing aircraft_id');
        }
        $aircraft_id = $json['aircraft']['aircraft_id'];
        $flight = Flight::fromJson($json);
        MyFlyFunDb::$shared->createFlight($flight, $aircraft_id);
    }
}


