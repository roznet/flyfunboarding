<?php

class FlightController extends Controller
{
    public function plan($params) {
        $this->validateMethod('POST');

        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_id', 0);
        $aircraft = MyFlyFunDb::$shared->getAircraft($aircraft_id, false);
        
        if (is_null($aircraft)) {
            $this->terminate(400, 'Aircraft does not exist');
        }

        $json = $this->getJsonPostBody();
        $json['aircraft'] = $aircraft->toJson();
        $flight = Flight::fromJson($json);
        $flight->aircraft_id = $aircraft_id;
        MyFlyFunDb::$shared->createOrUpdateFlight($flight);
    }
}


