<?php

class AirportController {

    function index() {
        if (isset($_GET['icao'])){
            $this->airportFromIcao($_GET['icao']);
            return true;
        }

        return false;

    }

    function info($params) {
        // check params has 1 parameters
        if (count($params) != 1) {
            return false;
        }
        $this->airportFromIcao($params[0]);
        return true;
    }

    private function airportFromIcao(string $icao) {
        $airport = new Airport($icao);
        print(json_encode($airport->getInfo()));
    }
}
