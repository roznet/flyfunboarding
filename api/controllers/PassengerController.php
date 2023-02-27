<?php

class PassengerController {
    public function create() {
        $json = json_decode(file_get_contents('php://input'), true);
        $passenger = Passenger::fromJson($json);
        MyFlyFunDb::$shared->createOrUpdatePassenger($passenger);
    }

    public function list() {
        $passengers = MyFlyFunDb::$shared->listPassengers();
        $json = json_encode($passengers);
        echo $json;
    }
}
