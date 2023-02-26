<?php

class DbController {
    public function setup() {
        MyFlyFunDb::$shared->setup();
    }

}
