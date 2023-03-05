<?php

class AircraftController extends Controller {

    public function index($params) {
        $this->validateMethod('GET');
        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_id', 0);
        $aircraft = MyFlyFunDb::$shared->getAircraft($aircraft_id);
        if ($aircraft) {
            $json = json_encode($aircraft);
            $this->contentType('application/json');
            echo( $json );
        } else {
            $this->terminate(404, "Aircraft not found");
        }   

    }
    public function create() {
        $this->validateMethod( 'POST' );
        $json = $this->getJsonPostBody();
        $aircraft = Aircraft::fromJson($json);
        MyFlyFunDb::$shared->createOrUpdateAircraft($aircraft);
    }

    public function list() {
        $this->validateMethod('GET');
        
        $aircrafts = MyFlyFunDb::$shared->listAircrafts();
        $json = json_encode($aircrafts);
        $this->contentType('application/json');
        echo( $json );
    }
}
