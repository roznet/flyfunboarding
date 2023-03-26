<?php

// Database table structure:
//      Tickets:    ticket_id, passenger_id, flight_id, json_data 
//      Passengers: passenger_id, json_data
//      Flights:    flight_id, aircraft_id, json_data
//      BoardingPasses: boarding_pass_id, ticket_id, json_data
//      Aircrafts:  aircraft_id, registration, json_data
//
//      
class MyFlyFunDb {

    const MISSING_ID = -1;

    public static $shared = null;
    public $db;
    public $airline_id = -1;

    public function __construct() {
        $config = Config::$shared;
        $this->db = mysqli_connect( $config['db_host'], $config['db_username'], $config['db_password'], $config['database'] );
    }

    public function setup() {
        $this->createTableIfNecessary();
    }
    public function forceSetup() {
        $this->dropTables();
        $this->createTableIfNecessary();
    }
    static $standardTables = [
            "Flights" => [ "link" => [ "Aircrafts" ] ],
            "Passengers" => [],
            "Tickets" => [ "link" => [ "Passengers", "Flights" ] ],
            "Aircrafts" => []
    ];
    static $tableCreationOrder = [ "Aircrafts", "Passengers", "Flights", "Tickets" ];

    private function tableToId($table) {
        return substr(strtolower($table), 0, -1) . '_id';
    }
    private function tableToIdentifier($table) {
        return substr(strtolower($table), 0, -1) . '_identifier';
    }
    private function tableToClass($table) {
        return ucfirst(substr($table, 0, -1));
    }
    private function classToTable($class) {
        return $class . 's';
    }
    private function tableToLinkVariable($table) {
        return substr(strtolower($table), 0, -1);
    }

    function tableToSqlReference($table) {
        return strtolower(substr($table,0,2));
    }
    function tableToStatsColumnName($table, $stat) {
        return strtolower($table) . '_' . $stat;
    }

    public function dropTables(){
        $tables = MyFlyFunDb::$standardTables;

        foreach (array_keys($tables) as $table ) {
            mysqli_query($this->db, "DROP TABLE IF EXISTS $table");
        }

        mysqli_query($this->db, "DROP TABLE IF EXISTS Airlines");
    }

    public function createTableIfNecessary() {
        // refactor current function to create tables from an array of string of queries
        $queries = [];
        $queries = [ "CREATE TABLE IF NOT EXISTS Airlines (airline_id INT NOT NULL AUTO_INCREMENT, json_data JSON, airline_identifier VARCHAR(255) UNIQUE, modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, PRIMARY KEY (airline_id))" ];
        foreach (MyFlyFunDb::$tableCreationOrder as $table) {
            $tableInfo = MyFlyFunDb::$standardTables[$table];
            // generate id name: lowercase table name without the last character if it's an s
            $table_id =  $this->tableToId($table);
            $identifier = $this->tableToIdentifier($table);
            $links = [];
            if (isset($tableInfo['link'])) {
                $links = $tableInfo['link'];
            }
            $columns = [ $table_id . " INT NOT NULL AUTO_INCREMENT", $identifier . " VARCHAR(36) UNIQUE DEFAULT (uuid())" ];
            foreach( $links as $link ) {
                $link_id = $this->tableToId($link);
                $columns[] = $link_id . " INT NOT NULL";
            }
            $columns[] = "json_data JSON";
            $columns[] = "airline_id INT NOT NULL";
            $columns[] = "modified TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP";
            $columns[] = "PRIMARY KEY ({$table_id})" ;
            $columns[] = "FOREIGN KEY (airline_id) REFERENCES Airlines(airline_id) ON DELETE CASCADE";
            foreach( $links as $link ) {
                $link_id = $this->tableToId($link);
                $columns[] = "FOREIGN KEY ({$link_id}) REFERENCES {$link}({$link_id}) ON DELETE CASCADE";
            }
            $queries[] = "CREATE TABLE IF NOT EXISTS $table (" . implode(", ", $columns) . ")";
        }

        foreach ($queries as $query) {
            print("Executing query: $query".PHP_EOL);
            mysqli_query($this->db, $query);
            $this->checkNoErrorOrDie($query);
        }
    }

    private function checkNoErrorOrDie($sql) {
        if (mysqli_errno($this->db)) {
            http_response_code(500);
            die("Error executing query: $sql, error: " . mysqli_error($this->db));
        }
    }
                

    private function validateAirline() {
        if( $this->airline_id == -1 ) {
            die("Airline not set");
        }
    }

    static function uniqueIdentifier(string $identifier) : string {
        if( Airline::$current === null ) {
            return hash('sha256',$identifier);
        }

        return hash('sha256',Airline::$current->airline_id . '.' . $identifier);
    }

    private function createOrUpdate($table, $object) {
        $this->validateAirline();
        $json = json_encode($object->toJson());

        $table_id = $this->tableToId($table);
        $identifier = $this->tableToIdentifier($table);
    
        $tableInfo = MyFlyFunDb::$standardTables[$table];
        $links = [];
        if (isset($tableInfo['link'])) {
            $links = $tableInfo['link'];
        }

        $types =  ['si'];
        $values = [$json, $this->airline_id];
        $cols = ['json_data','airline_id'];

        foreach( $links as $link ) {
            $link_id = $this->tableToId($link);
            $types[] = "i";
            $values[] = $object->$link_id;
            $cols[] = $link_id;
        }

        if( !is_null($object->$identifier) && $object->$identifier != ""){
            $types[] = "s";
            $values[] = $object->$identifier;
            $cols[] = $identifier;
        }

        // If we already have a table_id, then update values instead of INSERT
        if( $object->$table_id > 0 ) {
            $types[] = "i";
            $values[] = $object->$table_id;
            $cols[] = $table_id;
        }
        
        $sql = "INSERT INTO $table (" . implode(", ", $cols) . ") VALUES (" . implode(", ", array_fill(0, count($cols), "?")) . ")";
        $sql .= "ON DUPLICATE KEY UPDATE json_data = VALUES(json_data), ". $identifier . " = VALUES(" . $identifier . ")";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param(implode("", $types), ...$values);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $object->$table_id = mysqli_insert_id($this->db);
        // retrieve the object either by last insert id or identifier if already existing
        if($object->$table_id == 0) {
            $sql = "SELECT $table_id,$identifier FROM $table WHERE $identifier = ?";
            $stmt = mysqli_prepare($this->db, $sql);
            $stmt->bind_param("s", $object->$identifier);
        }else{
            $sql = "SELECT $table_id,$identifier FROM $table WHERE $table_id = ?";
            $stmt = mysqli_prepare($this->db, $sql);
            $stmt->bind_param("i", $object->$table_id);
        }
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        $this->addIdentifiers($table, $object, $row);

        return $object;
    }

    private function addLinks($table, $object, $row) {
        $tableInfo = MyFlyFunDb::$standardTables[$table];
        if (isset($tableInfo['link'])) {
            foreach ($tableInfo['link'] as $link) {
                $link_id = $this->tableToId($link);
                $object->$link_id = $row[$link_id];

                $linkObject = $this->getById($link, $row[$link_id]);
                if( $linkObject != null ) {
                    $linkvar = $this->tableToLinkVariable($link);
                    $object->$linkvar = $linkObject;
                }
            }
        }
    }
    private function addIdentifiers($table, $object, $row) {
        $tableId = $this->tableToId($table);
        $tableIdentifier = $this->tableToIdentifier($table);
        if( isset($row[$tableIdentifier]) ) {
            $object->$tableIdentifier = $row[$tableIdentifier];
        }
        else {
            $object->$tableIdentifier = "MISSING";
        }
        if( isset($row[$tableId]) ) {
            $object->$tableId = $row[$tableId];
        }
    }

    // Query example with a join
    // SELECT p.passenger_id, p.json_data, COUNT(t.flight_id) 
    // FROM Passengers p
    // LEFT JOIN Tickets t ON p.passenger_id  = t.passenger_id
    // GROUP BY p.passenger_id
    //
    //
    private function list($table, $where = []) : array {
        $this->validateAirline();
        $sql = "SELECT * FROM $table";
        $clause = [ 'airline_id = ' . $this->airline_id];
        if( count($where) > 0 ) {
            foreach( $where as $key => $value ) {
                $clause[] = $key . ' = ' . $value;
            }
        }
        $sql .= ' WHERE ' . implode(' AND ', $clause);
        $result = mysqli_query($this->db, $sql);
        $this->checkNoErrorOrDie($sql);
        $objects = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $json = json_decode($row['json_data'], true);
            $object = JsonHelper::fromJson($json, $this->tableToClass($table));
            $this->addIdentifiers($table, $object, $row);
            $this->addLinks($table, $object, $row);
            $objects[] = $object->toJson();
        }
        return $objects;
    }

    private function addStats($object, $row, $joins){
        $stats = [];
        foreach( $joins as $join ) {
            $joinCount = $this->tableToStatsColumnName($join, 'count');
            $joinLast = $this->tableToStatsColumnName($join, 'last');

            $stat = new Stats();
            $stat->count = $row[$joinCount];
            if( isset($row[$joinLast]) ) {
                $stat->last = new DateTime($row[$joinLast]);
            }
            else {
                $stat->last = null;
            }
            $stat->table = $join;
            $stats[] = $stat;
        }
        $object->stats = $stats;
    }

    // SELECT p.*, COUNT(t.ticket_id) as ticket_id_count, MAX(t.modified) as ticket_last FROM Passengers p LEFT JOIN Tickets t ON p.passenger_id = t.passenger_id GROUP BY p.passenger_id
    function listStats($table, $where = [], $joins = []) : array {
        $this->validateAirline();
        $tableRef = $this->tableToSqlReference($table);
        $select = ["{$tableRef}.*"];
        $leftJoin = [];
        foreach( $joins as $joinTable) {
            $joinTableRef = $this->tableToSqlReference($joinTable);
            $joinId = $this->tableToId($joinTable);
            $joinCount = $this->tableToStatsColumnName($joinTable, 'count');
            $joinLast = $this->tableToStatsColumnName($joinTable, 'last');
            $select[] = "COUNT({$joinTableRef}.{$joinId}) as {$joinCount}";
            $select[] = "MAX({$joinTableRef}.modified) as {$joinLast}";
            $tableId = $this->tableToId($table);
            $leftJoin[] = "{$joinTable} {$joinTableRef} ON {$tableRef}.{$tableId} = {$joinTableRef}.{$tableId}";
        }
        $clause = [ $tableRef.'.airline_id = ' . $this->airline_id];
        if( count($where) > 0 ) {
            foreach( $where as $key => $value ) {
                $clause[] = $key . ' = ' . $value;
            }
        }
        $sql = "SELECT " . implode(',', $select) . " FROM $table {$tableRef}";
        if( count($leftJoin) > 0 ) {
            $sql .= ' LEFT JOIN ' . implode($leftJoin);
        }
        $sql .= ' WHERE ' . implode(' AND ', $clause);
        $sql .= ' GROUP BY ' . $tableRef . '.' . $this->tableToId($table);
        $result = mysqli_query($this->db, $sql);
        $this->checkNoErrorOrDie($sql);
        $objects = [];
        while ($row = mysqli_fetch_assoc($result)) {
            $json = json_decode($row['json_data'], true);
            $object = JsonHelper::fromJson($json, $this->tableToClass($table));
            $this->addIdentifiers($table, $object, $row);
            $this->addLinks($table, $object, $row);
            $this->addStats($object, $row, $joins);
            $objects[] = $object->toJson();
        }
        return $objects;
    }

    // Function to get all row from a table, with optional $where array and doing
    // a left join on links in the $link argument with a count
    //function listStats($table, $where = [], $link = []) {

    private function directGet($table,$id) {
        $sql = "select * from $table where " . $this->tabletoidentifier($table) . " = ?"; 
        $stmt = mysqli_prepare($this->db,$sql);
        $stmt->bind_param("s", $id );
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        if( isset($row['airline_id']) ) {
            $airline = $this->getAirlineById($row['airline_id']);
            Airline::$current = $airline;
            MyFlyFunDb::$shared->airline_id = $airline->airline_id;
        }

        $json = json_decode($row['json_data'], true);
        $object = jsonhelper::fromjson($json, $this->tabletoclass($table));
        $this->addIdentifiers($table, $object, $row);
        $this->addlinks($table, $object, $row);
        return $object;
    }

    private function getById($table,int $id) {
        $sql = "select * from $table where " . $this->tableToId($table) . " = ? and airline_id = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("ii", $id, $this->airline_id);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $json = json_decode($row['json_data'], true);
        $object = jsonhelper::fromjson($json, $this->tabletoclass($table));
        $this->addIdentifiers($table, $object, $row);
        $this->addlinks($table, $object, $row);
        return $object;
    }

    private function get($table,$id) {
        $this->validateAirline();
        $sql = "select * from $table where " . $this->tabletoidentifier($table) . " = ? and airline_id = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("si", $id, $this->airline_id);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $json = json_decode($row['json_data'], true);
        $object = jsonhelper::fromjson($json, $this->tabletoclass($table));
        $this->addIdentifiers($table, $object, $row);
        $this->addlinks($table, $object, $row);
        return $object;
    }

    private function delete($object) : bool {
        $this->validateAirline();
        $table = $this->classToTable(get_class($object));
        $tableIdentifier = $this->tableToIdentifier($table);
        $id = $object->$tableIdentifier;
        if( $id == null ) {
            return false;
        }
        $sql ="DELETE FROM $table WHERE " . $this->tableToIdentifier($table) . " = ? AND airline_id = ?" ;
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("si", $id, $this->airline_id);
        $rv = $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        return $rv;
    }

    // Airlines
    // creation and update of airline is special because we need to check for existing airline on the apple_identifier
    public function createOrUpdateAirline($json) {
        $airline = JsonHelper::fromJson($json, Airline::class);
        $existing = $this->getAirlineByAppleIdentifier($airline->apple_identifier);
        if( $existing != null ) {
            $airline->airline_id = $existing->airline_id;
            $airline->airline_identifier = $existing->airline_identifier;
            $sql = 'UPDATE Airlines SET json_data = ? WHERE airline_id = ?';
            $stmt = mysqli_prepare($this->db, $sql);
            $json_str = json_encode($json);
            $stmt->bind_param("si", $json_str, $airline->airline_id);
            $stmt->execute();
            $this->checkNoErrorOrDie($sql);
            return $airline;
        }else{
            $sql = 'INSERT INTO Airlines (airline_identifier, json_data) VALUES (?, ?) ON DUPLICATE KEY UPDATE json_data = VALUES(json_data)';
            $stmt = mysqli_prepare($this->db, $sql);
            $json_str = json_encode($json);
            $airlineIdentifier = Airline::airlineIdentifierFromAppleIdentifier($airline->apple_identifier);
            $stmt->bind_param("ss", $airlineIdentifier, $json_str);
            $stmt->execute();
            $this->checkNoErrorOrDie($sql);
            $airline_id = mysqli_insert_id($this->db);
            $rv = $this->getAirlineById($airline_id);
            return $rv;
        }
    }

    public function getAirlineByAppleIdentifier($apple_identifier){
        $airlineIdentifier = Airline::airlineIdentifierFromAppleIdentifier($apple_identifier);
        $sql = "SELECT * FROM Airlines WHERE airline_identifier = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("s", $airlineIdentifier);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Airline::class);
        $this->addIdentifiers('Airlines', $object, $row);
        return $object;
    }
    public function getAirlineById($airline_id){
        $sql = "SELECT * FROM Airlines WHERE airline_id = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("i", $airline_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Airline::class);
        $this->addIdentifiers('Airlines', $object, $row);
        return $object;
    }

    public function deleteAirlineById($airline_id){
        $sql = "DELETE FROM Airlines WHERE airline_id= ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("i", $airline_id);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
    }
    public function getAirlineByAirlineIdentifier($airline_identifier){
        $sql = "SELECT * FROM Airlines WHERE airline_identifier = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("s", $airline_identifier);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Airline::class);
        $this->addIdentifiers('Airlines', $object, $row);
        return $object;
    }

    // Aircrafts
    //
    public function createOrUpdateAircraft(Aircraft $aircraft) : ?Aircraft {
        return $this->createOrUpdate("Aircrafts", $aircraft);
    }
    public function listAircrafts() : array {
        return $this->listStats("Aircrafts", [], ['Flights']);
    }
    public function getAircraft($aircraft_id) : ?Aircraft{
        return $this->get("Aircrafts", $aircraft_id);
    }
    public function deleteAircraft(Aircraft $aircraft) : bool {
        return $this->delete($aircraft);
    }

    // Passengers
    public function createOrUpdatePassenger(Passenger $passenger) : ?Passenger {
        return $this->createOrUpdate("Passengers", $passenger);
    }

    public function listPassengers() : array {
        return $this->listStats("Passengers", [], ['Tickets']);
    }

    public function getPassenger($passsenger_id ) : ?Passenger {
        return $this->get("Passengers", $passsenger_id );
    }
    public function deletePassenger(Passenger $passenger) {
        return $this->delete($passenger);
    }

    // Flights
    public function createOrUpdateFlight(Flight $flight) : ?Flight {
        return $this->createOrUpdate("Flights", $flight);
    }

    public function listFlights() : array {
        return $this->listStats("Flights", [], ['Tickets']);
    }

    public function listFlightsForAircraft(Aircraft $aircraft) : array {
        return $this->list("Flights", ["aircraft_id" => $aircraft->aircraft_id]);
    }

    public function getFlight($flight_id) : ?Flight {
        return $this->get("Flights", $flight_id);
    }

    public function deleteflight(Flight $flight) : bool {
        return $this->delete($flight);
    }

    // Tickets
    public function createOrUpdateTicket(Ticket $ticket) : ?Ticket {
        return $this->createOrUpdate("Tickets", $ticket);
    }
    public function deleteTicket(Ticket $ticket) : bool {
        return $this->delete($ticket);
    }

    public function getTicket(string $ticket_id) : ?Ticket {
        return $this->get("Tickets", $ticket_id);
    }
    public function directGetTicket(string $ticket_id) : ?Ticket {
        return $this->directGet("Tickets", $ticket_id);
    }
    public function getTicketByFlightAndPassenger(int $flight_id, int $passenger_id) : ?Ticket {
        $sql = "SELECT * FROM Tickets WHERE flight_id = ? AND passenger_id = ?";
        $stmt = mysqli_prepare($this->db, $sql);
        $stmt->bind_param("ii", $flight_id, $passenger_id);
        $stmt->execute();
        $this->checkNoErrorOrDie($sql);
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
            return null;
        }
        $row = $result->fetch_assoc();
        $object = JsonHelper::fromJson(json_decode($row['json_data'], true), Ticket::class);
        $this->addIdentifiers('Tickets', $object, $row);
        return $object;
    }

    public function listTickets() : array {
        return $this->list("Tickets");
    }
    public function listTicketsForPassenger(Passenger $passenger) : array {
        return $this->list("Tickets", ["passenger_id" => $passenger->passenger_id]);
    }

}
if (is_null(MyFlyFunDb::$shared)) {
    MyFlyFunDb::$shared = new MyFlyFunDb();
}
