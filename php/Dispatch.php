<?php

class Dispatch {
    private string $url;

    public function __construct(string $url) {
        $this->url = $url;
    }

    public function dispatch() {
        $urlParts = explode('/', $this->url);
        $version = $urlParts[0];
        if ($version != 'v1') {
            print("Invalid Version");
            return false;
        }
        $controller = $urlParts[1];
        if (isset($urlParts[2])) {
            $action = $urlParts[2];
            $params = array_slice($urlParts, 3);
        } else {
            $action = 'index';
            $params = array_slice($urlParts, 2);
        }

        $controllerName = ucfirst($controller) . 'Controller';
        $controllerPath = 'controllers/' . $controllerName . '.php';

        if (file_exists($controllerPath)) {
            require_once $controllerPath;
            $controller = new $controllerName();
            if (method_exists($controller, $action)) {
                return $controller->$action($params);
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
