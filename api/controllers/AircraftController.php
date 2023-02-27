<?php

class AircraftController {

    public function create() {
        $json = json_decode(file_get_contents("php://input"), true);
        $aircraft = Aircraft::fromJson($json);
        MyFlyFunDb::$shared->createOrUpdateAircraft($aircraft);
    }

    public function list() {
        $aircrafts = MyFlyFunDb::$shared->listAircrafts();
        $json = json_encode($aircrafts);
        print( $json );
    }
}
