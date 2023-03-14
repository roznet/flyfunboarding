<?php

class Dispatch {
    private string $url;

    public function __construct(string $url) {
        $this->url = $url;
    }

    public function dispatch() {
        $urlParts = explode('/', $this->url);

        // If first part is a version, check it and remove it
        $version = $urlParts[0];
        // if matches v[0-9]+, it's a version
        if (preg_match('/v[0-9]+/', $version)) {
            $urlParts = array_slice($urlParts, 1);
        } else {
            $version = 'v1';
        }
        if ($version != 'v1') {
            print("Invalid Version");
            return false;
        }

        // check if we have an airline identifier before a valid controller
        // else dispatch to the airline controller
        $airline_identifier = null;
        // first need to have at least 3 parts: airline/identifier/controller
        if( $urlParts[0] == 'airline' && count($urlParts) > 2){
            $check_identifier = $urlParts[1];
            $check_controller = $urlParts[2];
            // if the identifier is not a valid AirlineController method then we'll try it as an airline identifier
            //
            if( !method_exists('AirlineController', $check_controller) ){
                $airline_identifier = $check_identifier;
            }
        }

        if ($airline_identifier !== null) {
            $urlParts = array_slice($urlParts, 2);
            $airline = MyFlyFunDb::$shared->getAirlineByAirlineIdentifier($airline_identifier);
            if( $airline === null ){
                http_response_code(401);
                die("Invalid Airline $airline_identifier");
            }
            if( !$airline->validate()) {
                http_response_code(401);
                die("Invalid Bearer Token");
            }
            Airline::$current = $airline;
            MyFlyFunDb::$shared->airline_id = $airline->airline_id;
        }
        // Then check if controller exists
        $controller = array_shift($urlParts);

        $controllerName = ucfirst($controller) . 'Controller';
        $controllerPath = 'controllers/' . $controllerName . '.php';

        if (file_exists($controllerPath)) {
            require_once $controllerPath;
            $controller = new $controllerName();

            // Then check if action exists, if so, call it with the rest as parameters
            // if not, check if index exists, and call it with all remaining parts as parameters
            if (isset($urlParts[0])) {
                $actionRaw = $urlParts[0];
                $params = array_slice($urlParts, 1);
            } else {
                $actionRaw = 'index';
                $params = $urlParts;
            }
            $actionWithRequestMethod = $actionRaw . "_" . strtolower($_SERVER['REQUEST_METHOD']);
            foreach([$actionWithRequestMethod, $actionRaw] as $action){
                if (method_exists($controller, $action)) {
                    return $controller->$action($params);
                }
            }
            // can't be part of above loop because in this case the params should be the urlParts
            // and not the params, as the first part of urlParts is not an action but a parameter
            if (method_exists($controller, 'index')) {
                return $controller->index($urlParts);
            }
            // If we get here, the action was not found
            http_response_code(400);
            print("Method not found");
        } else {
            http_response_code(400);
            print("Controller not found");
        }

        return false;
    }
}
