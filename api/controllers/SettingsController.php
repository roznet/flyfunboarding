<?php

class SettingsController extends Controller {
    function index() {
        $this->validatemethod( 'GET' );
        $airline = airline::$current;
        $this->contenttype('application/json');
        echo json_encode($airline->settings()->json);
    }

    function index_post() {
        $this->validateMethod( 'POST' );

        $json = $this->getJsonPostBody();

        $airline = Airline::$current;
        $updated = MyFlyFunDb::$shared->updateAirlineSettings($airline->airline_id, $json);
        echo json_encode($updated->json);
    }
}

