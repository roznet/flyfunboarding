<?php

class AirportController extends Controller {

    function index() {
        if (isset($_GET['icao'])){
            $this->airportFromIcao($_GET['icao']);
        }else{
            $this->terminate(400, "Bad Request, Airport not found");
        }
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
        $info = $airport->getInfo();
        if ($info == null) {
            $this->terminate(400, "Bad Request, Airport not found");
        }
        $this->contentType("application/json");
        print(json_encode($airport->getInfo()));
    }
}
