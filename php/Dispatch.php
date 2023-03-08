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

        // if second part is airline with a number, check it and remove it
        if ($urlParts[0] == 'airline' && preg_match('/[0-9]+/', $urlParts[1]) && count($urlParts) > 2) {
            $airline_id = $urlParts[1];
            $urlParts = array_slice($urlParts, 2);
            $airline = MyFlyFunDb::$shared->getAirline($airline_id);
            if( !$airline->validate()) {
                http_response_code(401);
                die("Invalid Bearer Token");
            }
            MyFlyFunDb::$shared->airline_id = $airline_id;
        }else{
            $airline_id = -1;
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
                $action = $urlParts[0];
            } else {
                $action = 'index';
            }
            if (method_exists($controller, $action)) {
                $params = array_slice($urlParts, 1);
                return $controller->$action($params);
            }else if (method_exists($controller, 'index')) {
                $params = $urlParts;
                return $controller->index($params);
            } else {
                http_response_code(400);
                print("Method not found");
            }
        } else {
            http_response_code(400);
            print("Controller not found");
        }

        return false;
    }
}
