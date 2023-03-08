<?php

class AirlineController extends Controller {

    function create() {
        $this->validateMethod( 'POST' );
        $json = $this->getJsonPostBody();
        print_r($json);

        MyFlyFunDb::$shared->createOrUpdateAirline($json);
    }

    function index($params){
        $this->validateMethod( 'GET' );
        $airline_id = $params[0];
        $airline = MyFlyFunDb::$shared->getAirline($airline_id);
        if( !$airline->validate() ) {
            http_response_code(401);
            die("Invalid Bearer Token");
        }
        echo json_encode($airline->toJson());
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
