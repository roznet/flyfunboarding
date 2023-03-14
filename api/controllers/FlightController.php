<?php

class FlightController extends Controller
{

    public function index_delete($params) {
        $this->validateMethod('DELETE');

        $flight_id = $this->paramByPositionOrGet($params, 'flight_id', 0);
        $flight = MyFlyFunDb::$shared->getFlight($flight_id, false);

        if (is_null($flight)) {
            $this->terminate(400, 'Flight does not exist');
        }
        $status = MyFlyFunDb::$shared->deleteFlight($flight);
        $this->contentType('application/json');
        echo json_encode(array('status' => $status, 'flight_identifier' => $flight->uniqueIdentifier()['flight_identifier']));
    }
    
    public function index($params) {
        $this->validateMethod('GET');

        $flight_id = $this->paramByPositionOrGet($params, 'flight_id', 0);
        $flight = MyFlyFunDb::$shared->getFlight($flight_id, false);

        if (is_null($flight)) {
            $this->terminate(400, 'Flight does not exist');
        }
        $json = json_encode($flight->toJson());
        $this->contentType('application/json');
        echo $json;
    }

    public function plan_post($params) {
        $this->validateMethod('POST');

        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_id', 0);
        $aircraft = MyFlyFunDb::$shared->getAircraft($aircraft_id, false);
        
        if (is_null($aircraft)) {
            $this->terminate(400, 'Aircraft does not exist');
        }

        $json = $this->getJsonPostBody();
        $json['aircraft'] = $aircraft->toJson();
        $flight = Flight::fromJson($json);
        $flight = MyFlyFunDb::$shared->createOrUpdateFlight($flight);
        $json = json_encode($flight->toJson());
        $this->contentType('application/json');
        echo $json;
    }

    public function list($params) {
        $this->validateMethod('GET');

        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_id', 0, true);
        if ($aircraft_id === null) {
            $aircraft_id = -1;
        }

        $flights = MyFlyFunDb::$shared->listFlights($aircraft_id);
        $json = json_encode($flights);
        $this->contentType('application/json');
        echo $json;
    }
}


