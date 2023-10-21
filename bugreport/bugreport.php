<?php

include_once('config_bugreport.php');

class bugreport
{
    public $sql;
    public $bug_data_directory;
    public $verbose = false;   
    public $debug = false;
    public $table_prefix;
    public $defaultApplicationName;

    var $table_status;
    var $table_minimum_version;
    var $table_bugreports;
    var $email_bug_to;

    var $minimum_app_version;
    var $minimum_system_version;
    var $minimum_version_message;
    var $disabled;
    var $message;
    var $state;
    var $message_date;
    var $new_id;
    var $common_id;
    var $application;
    var $error;
    var $fields;
    var $list_url;
    var $updated;

    function query_first_row($query)
    {
        return $this->sql->query_first_row($query);
    }
    var $start_ts;

    function log(){
        $args = func_get_args();
        $tag = array_shift( $args );
        $fmt = array_shift( $args );

        $msg = vsprintf( $fmt, $args );
        
        printf( "%s:%.3f: %s".PHP_EOL, $tag, microtime(true)-$this->start_ts, $msg );
    }

    function table_exists($table)
    {
        return $this->sql->table_exists($table);
    }

    function insert_or_update($table, $row, $id_array = array()){
        $this->sql->insert_or_update( $table, $row, $id_array );
    }

    function create_or_alter($table, $fields, $drop = false)
    {
        $this->sql->create_if_required($table, $fields, $drop);
    }


    function max_value($table, $field)
    {
        return $this->sql->max_value($table, $field);
    }



    function __construct()
    {

        $this->start_ts = microtime(true);
        $bug_config = config_bugreport::$shared;

        $this->sql = new sql_helper();

        $this->bug_data_directory = $bug_config['bug_data_directory'];
        if (isset($bug_config['email_bug_to'])) {
            $this->email_bug_to = $bug_config['email_bug_to'];
        } else {
            $this->email_bug_to = NULL;
        }

        $this->verbose = isset($_GET['verbose']);
        if( $this->verbose ){
            $this->sql->verbose = true;
        }

        $this->debug = isset($_GET['debug']);
        if ($this->debug) {
            $this->verbose = true;
            print('<pre>DEBUG START' . PHP_EOL);
            $this->sql->verbose = true;
        }

        if(isset($bug_config['table_prefix'])){
            $this->table_prefix = $bug_config['table_prefix'];
        } else {
            $this->table_prefix = '';
        }
        $this->table_status = $this->table_prefix . 'app_status';
        $this->table_minimum_version = $this->table_prefix . 'minimum_version';
        $this->table_bugreports = $this->table_prefix . 'bugreports';

        if (!$this->table_exists($this->table_status)) {
            $this->create_or_alter($this->table_status, array(
                'status_id' => 'BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY',
                'ts' => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
                'state' => "ENUM( 'ok', 'disabled', 'message' )",
                'message' => 'TEXT',
            ));
            $this->create_or_alter($this->table_minimum_version, array(
                'version_id' => 'BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY',
                'ts' => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
                'app_minimum_version' => 'VARCHAR(32)',
                'system_minimum_version' => 'VARCHAR(32)',
                'message' => 'TEXT',
            ));
        }
        $row = $this->query_first_row(sprintf('SELECT * FROM %s ORDER BY version_id DESC LIMIT 1', $this->table_minimum_version));


        if( isset( $row['app_minimum_version'] ) ){
            $this->minimum_app_version = $row['app_minimum_version'];
            $this->minimum_system_version = $row['system_minimum_version'];
            $this->minimum_version_message = $row['message'];
        }else{
            $this->minimum_app_version = '1.0';
            $this->minimum_system_version = '1.0';
            $this->minimum_version_message = NULL;
        }
        $row = $this->query_first_row(sprintf('SELECT * FROM %s ORDER BY status_id DESC LIMIT 1', $this->table_status));

        if( isset( $row['state'] ) ){
            $this->disabled = ($row['state'] == 'disabled');
            $this->message  = $row['message'];
            $this->state    = $row['state'];
            $this->message_date = $row['ts'];
        }else{
            $this->disabled = false;
            $this->message = NULL;
            $this->state = 'ok';
        }

        $this->new_id = NULL;
        $this->common_id = -1;
        $this->application = $this->get_or_post('applicationName', 'ConnectStats');

        $this->error = NULL;

        $this->fields = array(
            'id' => 'INT UNSIGNED AUTO_INCREMENT PRIMARY KEY',
            'filename' => 'VARCHAR(256)',
            'platformString' => 'VARCHAR(256)',
            'applicationName' => 'VARCHAR(256)',
            'systemName' => 'VARCHAR(256)',
            'systemVersion' => 'VARCHAR(256)',
            'description' => 'TEXT',
            'version' => 'VARCHAR(256)',
            'email' => 'VARCHAR(256)',
            'commonid' => 'VARCHAR(256)',
            'filesize' => 'INT',
            'updatetime' => 'DATETIME',
            'replied' => 'DATETIME',
        );

        if (!$this->table_exists($this->table_bugreports)) {
            $this->create_or_alter($this->table_bugreports, $this->fields);
        }
        $this->list_url = sprintf('https://%s/%s', $_SERVER['HTTP_HOST'], str_replace('new.php', 'list.php', $_SERVER['REQUEST_URI']));
        $this->updated = false;

        if ($this->debug) {
            $this->verbose = true;
            print('DEBUG END</pre>' . PHP_EOL);
        }
    }

    function process()
    {
        if ($this->debug) {
            $this->build_debug_row();
            print_r(array_keys($_FILES));
            print_r($_POST);
        }

        if (isset($_FILES['file'])) {

            // this is the first stage when bug report is send with the bug report files
            $this->save_bugreport();
        } else if (isset($_GET['id'])) {
            // This is the second stage, when the form is submitted with the existing id and text information
            $this->update_bugreport();
        }
    }

    function status(){
        $this->row = array();
        foreach (array_keys($this->fields) as $field ) {
            if (isset($_GET[$field])) {
                if( $this->debug ){
                    printf('DEBUG extracting $row[%s] = %s' . PHP_EOL, $field, $_GET[$field]);
                }
                $this->row[$field] = $_GET[$field];
            }
        }

        if( $this->is_outdated_version() ){
            return [ 'status' => 0, 'message' => $this->minimum_version_message, 'app_minimum_version' => $this->minimum_app_version, 'system_minimum_version' => $this->minimum_system_version ];
        }elseif( $this->disabled ){
            return [ 'status' => 0, 'message' => $this->message, 'date' => $this->message_date ];
        }else{
            return [ 'status' => 1 ];
        }
    }
    
    function get_or_post($key, $default = NULL)
    {
        if (isset($_POST[$key])) {
            return ($_POST[$key]);
        } else if (isset($_GET[$key])) {
            return ($_GET[$key]);
        }
        return $default;
    }

    var $row;
    function update_bugreport()
    {
        // Display control
        if (isset($_GET['id'])) {
            $this->new_id = $_GET['id'];
            if (isset($_POST['description']) && $_POST['description']) {

                $this->row = array('description' =>  $_POST['description'], 'id' => $this->new_id);
                if (isset($_POST['email']) && $_POST['email']) {
                    $this->row['email'] = $_POST['email'];
                }
                $this->insert_or_update($this->table_bugreports, $this->row, array('id'));
                $this->updated = true;
            }
        }
    }


    function is_outdated_version()
    {
        return (isset($this->row['version']) && version_compare($this->row['version'], $this->minimum_app_version) == -1);
    }

    var $update_time;

    function saved_file_name( $name ){
       $file_dir = $this->update_time->format("Y/m");
       return sprintf( '%s/%s', $file_dir, $name );
    }

    function saved_file_full_path( $name ){
        $full_file_path = sprintf('%s/%s', $this->bug_data_directory, $name);
        $upload_dir = dirname( $full_file_path );
        if (!is_dir($upload_dir)) {
            if (!mkdir($upload_dir, 0777, true)) {
                print($full_file_path);
                die( sprintf('Internal misconfiguration, cannot make dir %s',$upload_dir) );
            }
        }
        return $full_file_path;
    }

    function save_bugreport()
    {
        if (is_dir($this->bug_data_directory) && isset($_FILES['file'])) {
            
            $this->update_time = new DateTime();
            
            $file = $_FILES['file'];
            $error = $file['error'];
            $this->new_id = $this->max_value($this->table_bugreports, 'id') + 1;

            if ($error == UPLOAD_ERR_OK) {
                $tmp_name = $file["tmp_name"];
                $saved_file_name = $this->saved_file_name( sprintf("bugreport_%s_%d.zip", $this->update_time->format("Ymd"), $this->new_id) );
                print($saved_file_name);
                $v = move_uploaded_file($tmp_name, $this->saved_file_full_path( $saved_file_name ));
                if (!$v) {
                    $saved_file_name = sprintf('ERROR: Failed to save %s to %s', $tmp_name, $saved_file_name);
                }
            } else {
                $saved_file_name = sprintf('ERROR: Failed to upload (error=%s)', $error);
            }

            $row = array('id' => $this->new_id);
            foreach (array_keys($this->fields) as $field) {
                if (isset($_POST[$field])) {
                    $row[$field] = $_POST[$field];
                } else {
                    if ($field == 'filename') {
                        if ($saved_file_name) {
                            $row[$field] = $saved_file_name;
                        }
                    } elseif ($field == 'applicationName') {
                        $row[$field] = 'ConnectStats';
                    }
                }
            }
            $row['updatetime'] = $this->update_time;
            if (!isset($row['commonid']) || $row['commonid'] == -1) {
                $this->common_id = $this->new_id;
                $row['commonid'] = $this->common_id;
            } else {
                $this->common_id = $row['commonid'];
            }
            $this->insert_or_update($this->table_bugreports, $row);
            $this->row = $row;
        }else{
            if($this->debug){
                print('DEBUG: not setup to save file');
            }
        }
    }

    function has_valid_email()
    {
        return (isset($this->row['email']) && strpos($this->row['email'], '@') !== false);
    }

    function send_email_if_necesssary()
    {
        // Report/email control
        if ($this->updated) {
            try {
                $row = $this->query_first_row(sprintf("SELECT * FROM %s WHERE id = %d", $this->table_bugreports, intval($this->new_id)));
                $this->update_time =  new DateTime( $row['updatetime'] );
                $msg = sprintf(
                    "Description: %s\nEmail: %s\nVersion: %s\nPlatform: %s\n",
                    $row['description'],
                    $row['email'],
                    $row['version'],
                    implode(' ', array($row['systemName'], $row['systemVersion'], $row['platformString']))
                );

                if (isset($row['filename'])) {
                    $saved_file_path = $this->saved_file_full_path( $row['filename'] );
                    if( is_readable( $saved_file_path ) ){
                        $z = new ZipArchive();

                        if ($z->open($saved_file_path)) {
                            if ($z->numFiles > 1) {
                                for ($i = 0; $i < $z->numFiles; $i++) {
                                    $info = $z->statIndex($i);
                                    $fn = $info['name'];
                                    $sz = $info['size'];
                                    if( $sz > 1048576 ){
                                        $sz = number_format( $sz/1048576,2). ' MB';
                                    }else{
                                        $sz = number_format( $sz/1024, 2 ). ' KB';
                                    }
                                    $msg .= sprintf("File: %s ($sz)" . PHP_EOL, $fn, $sz);
                                }
                            }
                        }
                    }
                } else {
                    $msg .= sprintf("File Failed to save %s" . PHP_EOL, $row['filename']);
                }
                $subject = $this->application . " BugReport";
                $headers = 'From: ConnectStats <bugreport@connectstats.app>' . "\r\n";
                if (strpos($row['email'], '@') === false) {
                    $subject = "$this->application Anonymous BugReport";
                } else {
                    $headers .= 'Reply-To: ' . $row['email'] . "\r\n";
                }
                $listurl = sprintf('https://%s/%s', $_SERVER['HTTP_HOST'], str_replace('bugreport/new', 'bugreport/list', $_SERVER['REQUEST_URI']));
                $msg .= sprintf('Bug report: %s', $listurl, PHP_EOL);
                if ($this->email_bug_to) {
                    if (!mail($this->email_bug_to, $subject, $msg, $headers)) {
                        print('<p>Failed to email!, please go to the <a href="https://ro-z.net">web site</a> or twitter <a href="https://twitter.com/connectstats">@connectstats</a> to report</p>' . PHP_EOL);
                    } else {
                        print('<h3>Email sent!</h3>');
                    }
                }
            } catch (Exception $e) {
                print("<pre>Failed to send email: " . $e->getMessage() . "</pre>");
            }
        }
    }

    function build_debug_row()
    {
        if ($this->debug) {
            $this->row = array();
            foreach (array_keys($this->fields) as $field) {
                if (isset($_GET[$field])) {
                    printf( 'DEBUG extracting $row[%s] = %s'.PHP_EOL, $field, $_GET[$field] );
                    $this->row[$field] = $_GET[$field];
                }
            }
        }
    }
}

