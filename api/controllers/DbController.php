<?php

class DbController {
    public function setup() {
        print( "setting up". PHP_EOL);
        MyFlyFunDb::$shared->setup();
    }

    public function create() {
        print_r($_REQUEST);
        print_r( $_FILES);
        print_r($_POST);
    }

}
