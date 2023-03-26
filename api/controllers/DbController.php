<?php

class DbController extends Controller {

    public function setup() {
        if( !$this->validateSystemCall() ) {
            $this->terminate(401, 'Unauthorized');
        }
        print( "setting up". PHP_EOL);
        MyFlyFunDb::$shared->setup();
    }

    public function test() {
        if( !$this->validateSystemCall() ) {
            $this->terminate(401, 'Unauthorized');
        }
        print_r($_REQUEST);
        print_r( $_FILES);
        print_r($_POST);
    }

    public function reset() {
        if( !$this->validateSystemCall() ) {
            $this->terminate(401, 'Unauthorized');
        }
        MyFlyFunDb::$shared->forceSetup();
    }
}
