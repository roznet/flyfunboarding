<?php

class AirlineController extends Controller {

    function create() {
        $this->validateMethod( 'POST' );
        $json = $this->getJsonPostBody();

        $airline = MyFlyFunDb::$shared->createOrUpdateAirline($json);
        if( $airline == null ) {
            http_response_code(400);
            die("Invalid Airline");
        }
        echo json_encode($airline->toJson());
    }

    function index($params){
        $this->validateMethod( 'GET' );
        $airline_id = $params[0];
        $airline = MyFlyFunDb::$shared->getAirlineByAirlineIdentifier($airline_id);
        if( !$airline->validate() ) {
            http_response_code(401);
            die("Invalid Bearer Token");
        }
        echo json_encode($airline->toJson());
    }


    function index_delete($params){
        $this->validateMethod( 'DELETE' );
        $airline_id = $params[0];
        $airline = MyFlyFunDb::$shared->getAirlineByAirlineIdentifier($airline_id);
        if( !$airline->validate() ) {
            http_response_code(401);
            die("Invalid Bearer Token");
        }
        MyFlyFunDb::$shared->deleteAirlineById($airline->airline_id);
        $this->contentType('application/json');
        echo json_encode(array('status' => 1, 'airline_identifier' => $airline->airline_identifier));
    }

    function get($params) {
        $this->validateMethod( 'GET' );
        $apple_identifier = $params[0];
        $airline = MyFlyFunDb::$shared->getAirlineByAppleIdentifier($apple_identifier);
        if( $airline == null ) {
            http_response_code(404);
            die("Airline not found");
        }
        if( !$airline->validate() ) {
            http_response_code(401);
            die("Invalid Bearer Token");
        }
        echo json_encode($airline->toJson());
    }
}
