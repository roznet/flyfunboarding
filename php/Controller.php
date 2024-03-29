<?php

class Controller {

    function contentType($type = 'application/json') {
        header('Content-Type: ' . $type);
    }

    function terminate($code, $message) {
        http_response_code($code);
        die($message);
    }
   function validateMethod( $method ) {
       if ( $_SERVER['REQUEST_METHOD'] != $method ) {
           $got = $_SERVER['REQUEST_METHOD'];
           $this->terminate(405, "Method $got not allowed, expected $method");
      }
   }
    function checkMethod($method) {
        return $_SERVER['REQUEST_METHOD'] == $method;
    }
    function getJsonPostBody() {
        $json = json_decode(file_get_contents("php://input"), true);
        return $json;
    }

    function paramByPositionOrGet($params, $name, $position, $optional = false){
        if ( isset($params[$position]) ) {
            return $params[$position];
        }else if( isset($_GET[$name]) ){
            return $_GET[$name];
        }
        if( !$optional ){
            $this->terminate(400, 'Bad request missing parameter: ' . $name);
        }else{
            return null;
        }
    }


    function validateSystemCall() : bool {
        $headers = apache_request_headers();
        if (!isset($headers['Authorization'])) {
            return false;
        }
        $bearer = str_replace("Bearer ", "", $headers['Authorization']);
        $secret = Config::$shared['secret'];
        return $bearer == $secret;
    }
}
