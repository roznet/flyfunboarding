<?php

class PassengerController extends Controller {
    public function create() {
        $this->validateMethod('POST');

        $json = $this->getJsonPostBody();
        $passenger = Passenger::fromJson($json);
        MyFlyFunDb::$shared->createOrUpdatePassenger($passenger);
    }

    public function list() {
        $this->validateMethod('GET');
        $passengers = MyFlyFunDb::$shared->listPassengers();
        $json = json_encode($passengers);
        $this->contentType('application/json');
        echo $json;
    }
}
