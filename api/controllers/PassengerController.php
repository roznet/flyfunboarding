<?php

class PassengerController extends Controller {
    public function create() {
        $this->validateMethod('POST');

        $json = $this->getJsonPostBody();
        $passenger = Passenger::fromJson($json);
        $passenger = MyFlyFunDb::$shared->createOrUpdatePassenger($passenger);
        if($passenger !== null){
            $json = json_encode($passenger);
            $this->contentType('application/json');
            echo $json;
        } else {
            $this->terminate(500, 'Error creating passenger');
        }
    }

    public function list() {
        $this->validateMethod('GET');
        $passengers = MyFlyFunDb::$shared->listPassengers();
        $json = json_encode($passengers);
        $this->contentType('application/json');
        echo $json;
    }

    public function index($params) {
        $this->validateMethod('GET');
        $passenger_id = $this->paramByPositionOrGet($params, 'passenger_id', 0);

        $passenger = MyFlyFunDb::$shared->getPassenger($passenger_id);
        if ($passenger ) {
            $json = json_encode($passenger);
            $this->contentType('application/json');
            echo $json;
        } else {
            $this->terminate(404, 'Passenger not found');
        }
    }
}
