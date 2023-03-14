<?php

class AircraftController extends Controller {

    public function index_flights(Aircraft $aircraft) {
        $flights = MyFlyFunDb::$shared->listFlightsForAircraft($aircraft);
        $json = json_encode($flights);
        $this->contentType('application/json');
        echo( $json );
    }

    public function index_delete($params) {
        $this->validateMethod('DELETE');
        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_identifier', 0);
        $aircraft = MyFlyFunDb::$shared->getAircraft($aircraft_id, false);
        if ($aircraft) {
            $status = MyFlyFunDb::$shared->deleteAircraft($aircraft);
            $this->contentType('application/json');
            echo json_encode(array('status' => $status, 'aircraft_identifier' => $aircraft->uniqueIdentifier()['aircraft_identifier']));
        } else {
            $this->terminate(404, "Aircraft not found");
        }
    }
    public function index($params) {
        $this->validateMethod('GET');
        $aircraft_id = $this->paramByPositionOrGet($params, 'aircraft_identifier', 0);
        $aircraft = MyFlyFunDb::$shared->getAircraft($aircraft_id, false);
        if ($aircraft) {
            // if more params do sub request
            if (count($params) > 1) {
                $sub_request = $this->paramByPositionOrGet($params, 'sub_request', 1);
                if( method_exists($this, 'index_'.$sub_request) ){
                    $this->{'index_'.$sub_request}($aircraft);
                    return;
                }

                // if sub request is not found
                $this->terminate(400, "Invalid request $sub_request");
            }else{

                $json = json_encode($aircraft->toJson());
                $this->contentType('application/json');
                echo( $json );
            }
        } else {
            $this->terminate(404, "Aircraft not found");
        }   

    }
    public function create() {
        $this->validateMethod( 'POST' );
        $json = $this->getJsonPostBody();
        $aircraft = Aircraft::fromJson($json);
        $aircraft = MyFlyFunDb::$shared->createOrUpdateAircraft($aircraft);
        if($aircraft !== null){
            $json = json_encode($aircraft->toJson());
            $this->contentType('application/json');
            echo( $json );
        } else {
            $this->terminate(500, 'Error creating aircraft');
        }
    }

    public function list(){
        $this->validateMethod('GET');
        
        $aircrafts = MyFlyFunDb::$shared->listAircrafts();
        $json = json_encode($aircrafts);
        $this->contentType('application/json');
        echo( $json );
    }
}
