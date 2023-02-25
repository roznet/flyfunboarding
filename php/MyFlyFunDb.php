<?php

// Database structure:
//      Tickets:    ticket_id, passenger_id, flight_id, seat, status
//      Passengers: passenger_id, json_data
//      Flights:    flight_id, json_data
//      BoardingPasses: boarding_pass_id, ticket_id, json_data
//
//      
class MyFlyFunDb {
    public static $shared = null;
    public $db;
    public function __construct() {
        $config = Config::$shared;
        $this->db = mysqli_connect( $config['db_host'], $config['db_username'], $config['db_password'], $config['database'] );
    }

    public function createDatabaseIfNecessary() {


    }
        

}
if (is_null(MyFlyFunDb::$db)) {
    MyFlyFunDb::$db = new MyFlyFunDb();
}
