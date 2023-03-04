<?php

class AircraftController extends Controller {

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
