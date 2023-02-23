<?php
class MyFlyFunDb {
    public static $shared = null;
    public $db;
    public function __construct() {
        $config = Config::$shared;
        $this->db = mysqli_connect( $config['db_host'], $config['db_username'], $config['db_password'], $config['database'] );
    }



}
if (is_null(MyFlyFunDb::$db)) {
    MyFlyFunDb::$db = new MyFlyFunDb();
}
