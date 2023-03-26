<?php

class PassengerController extends Controller {
    public function create() {
        $this->validateMethod('POST');

        $json = $this->getJsonPostBody();
        $passenger = Passenger::fromJson($json);
        $passenger = MyFlyFunDb::$shared->createOrUpdatePassenger($passenger);
        if($passenger !== null){
            $json = json_encode($passenger->toJson());
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
        if( is_null($passenger) ){
            $this->terminate(404, 'Passenger not found');
        }
        $tickets = $this->paramByPositionOrGet($params, 'tickets', 1, true);

        if (is_null($tickets) ) {
            $json = json_encode($passenger);
        }else{
            $tickets = MyFlyFunDb::$shared->listTicketsForPassenger($passenger);
            $json = json_encode($tickets);
        }
        $this->contentType('application/json');
        echo $json;
    }
    public function index_delete($params) {
        $this->validateMethod('DELETE');

        $passenger_id = $this->paramByPositionOrGet($params, 'passenger_id', 0);
        $passenger = MyFlyFunDb::$shared->getPassenger($passenger_id);
        if( is_null($passenger) ){
            $this->terminate(404, 'Passenger not found');
        }
        $result = MyFlyFunDb::$shared->deletePassenger($passenger);
        $this->contentType('application/json');
        echo json_encode(array('status' => $result, 'passenger_identifier' => $passenger->passenger_identifier));
    }
}
