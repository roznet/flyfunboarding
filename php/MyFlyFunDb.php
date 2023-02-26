<?php

// Database table structure:
//      Tickets:    ticket_id, passenger_id, flight_id, seat
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

    public function setup() {
        $this->createTableIfNecessary();
    }
    public function createTableIfNecessary() {
        // create flight table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Flights (flight_id INT NOT NULL, json_data JSON, PRIMARY KEY (flight_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Flights table: " . mysqli_error($this->db));
        }

        // create passenger table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Passengers (passenger_id INT NOT NULL, json_data JSON, PRIMARY KEY (passenger_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Passengers table: " . mysqli_error($this->db));
        }

        // create ticket table and check error
        mysqli_query($this->db, "CREATE TABLE IF NOT EXISTS Tickets (ticket_id INT NOT NULL, passenger_id INT NOT NULL, flight_id INT NOT NULL, seat VARCHAR(10), PRIMARY KEY (ticket_id))");
        if (mysqli_errno($this->db)) {
            die("Error creating Tickets table: " . mysqli_error($this->db));
        }
    }
        

}
if (is_null(MyFlyFunDb::$shared)) {
    MyFlyFunDb::$shared = new MyFlyFunDb();
}
