<?php

class KeysController extends Controller {
    function index() {
        $this->validateMethod( 'GET' );
        $airline = Airline::$current;
        $this->contentType('application/json');
        echo json_encode($airline->signer()->exportPublicKeys());

    }
}
