<?php
/**
 *
 */
include_once('autoload.php');

class sql_helper {
    public static $shared = null;

	var $connection;
    var $db_database = NULL;
    private $db_username = NULL;
    private $db_password = NULL;
	private $current_query = NULL;
	private $current_query_str = NULL;
    private $lasterror = NULL;

    private $fieldsInfo = NULL;
    private $tableInfo = NULL;
	
	private $readOnly = 0;	
	var $verbose = false;
    var $debug = false;
    private $start_ts;
	
    function __construct() {
        $api_config = config_bugreport::$shared;

		$this->db_database = $api_config['database'];
		$this->db_username = $api_config['db_username'];
		$this->db_password = $api_config['db_password'];;
		
		$this->connection = new mysqli($api_config['db_host'], $this->db_username, $this->db_password );
        if( ! $this->connection ){
			die( "Could not connect to the database: <br />");
		};
		$this->fieldsInfo = NULL;
		$this->tableInfo = NULL;
		$this->connection->select_db( $this->db_database );
        $this->connection->query( "SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'" );


        $this->start_ts = microtime(true);
	}
	
    //
    //	
    //	Constuctor and setup
    //
    //
    //
	function toString(){
		printf( "connection: %s<br />\n", $this->connection->info );
		printf( "database: %s<br />\n", $this->db_database );
		if( $this->current_query_str ){
			printf( "query str: %s<br />\n", $this->current_query_str );
		}
		if( $this->lasterror ){
			printf( "error: %s<br />\n", $this->lasterror );
		}
	}

	function printError(){
        if( $this->lasterror ){
            print( $this->toString() );
        }
	}
	
	function make_read_only(){
		$this->readOnly = 1;
	}
	function make_read_write(){
		$this->readOnly = 0;
	}
	function init_tableInfo( $force = false ){
		if( $this->fieldsInfo == NULL || $force == true ){
			$this->fieldsInfo = array();
			$this->tableInfo = array();
			$result = $this->connection->query( 'show tables' );
			if( $result ){
                while ($row = mysqli_fetch_row($result)) {
                    $this->tableInfo[ $row[0] ] = array();
                }
                foreach( array_keys($this->tableInfo) as $table){
                    $info_f = $this->connection->query( "DESCRIBE `$table`" );

                    while( $row_f = mysqli_fetch_array( $info_f ) ){
                        $this->fieldsInfo[ $row_f[ 'Field' ] ] = $row_f[ 'Type' ];
                        $this->tableInfo[ $table ][ $row_f[ 'Field' ] ] = $row_f[ 'Type' ];
                    };		
                }
            }else{
                if( $this->verbose ){
                    print( "INFO: empty db".PHP_EOL );
                }
            }
		};
	}

    //
    //
    //	Query Functions
    //
    //
	function query_as_structure( $query, $byfield, $allowmultiple = 0 ){
		$rv = array();
		$this->query_init( $query );
		while( $row = $this->query_next() ){
			if( ! isset( $row[ $byfield ] ) ){
				die( "can't index by $byfield , fields are: ".join(", ", array_keys( $row ) ) );
			};
			if( isset( $rv[ $row[ $byfield ] ] ) ){
                if( !$allowmultiple ){
					die( "can't index by $byfield , multiple values ".$row[ $byfield ] );
                }else{
                    array_push( $rv[ $row[ $byfield ] ],  $row );
                }
			}else{
                if($allowmultiple ){
                    $rv[ $row[ $byfield ] ] = array( $row );
                }else{
                    $rv[ $row[ $byfield ] ] = $row;
                }
			}
		};
		return( $rv );
	}
	function query_as_key_value( $query, $byfield, $valfield, $allowmultiple = 0 ){
		$rv = array();
		$this->query_init( $query );
		while( $row = $this->query_next() ){
			if( ! isset( $row[ $byfield ] ) ){
				die( "can't index by $byfield , fields are: ".join(", ", array_keys( $row ) ) );
			};
			if( isset( $rv[ $row[ $byfield ] ] ) ){
				if( !$allowmultiple )
					die( "can't index by $byfield , multiple values ".$row[ $byfield ] );
			}else{
				$rv[ $row[ $byfield ] ] = $row[ $valfield]; 
			}
		};
		return( $rv );
	}
	function query_as_html_table( $query, $links = NULL, $order = NULL ){
		$rv = "<table class=sqltable>\n";
		$this->query_init( $query );
		$titledone = false;
		$i=0;

        $key_order = NULL;
		while( $row = $this->query_next() ){
			if( ! $titledone ){
                if( $order ){
                    $all_keys = array_keys( $row );
                    $key_order = array();
                    
                    foreach( $order as $key ){
                        if( in_array( $key, $all_keys ) ){
                            array_push( $key_order, $key );
                        }
                    }
                    foreach( $all_keys as $key ){
                        if( ! in_array( $key, $key_order ) ){
                            array_push( $key_order, $key );
                        }
                    }
                }else{
                    $key_order = array_keys( $row );
                }
                $rv .= sprintf( "<tr><th>%s</th></tr>\n", join( '</th><th>',  $key_order) );
                $titledone = true;
			}
		 	$rowVal = array();
            foreach( $key_order as $key ){
                $cellVal = $row[$key];
                if( isset( $links[ $key ] ) ){
                    if( is_callable( $links[$key] ) ){
                        $cellVal = $links[$key]( $row );
                    }else{
                        $href = sprintf( $links[ $key ], $cellVal );
                        $cellVal = sprintf( '<a href="%s">%s</a>', $href , $cellVal );
                    }
                }
                
                array_push( $rowVal, $cellVal );
            }
		  	if( $i % 2 == 0 ){
                $rv .= sprintf( "<tr><td>%s</td></tr>\n", join( '</td><td>', $rowVal ) );
		  	}else{
                $rv .= sprintf( "<tr class=odd><td>%s</td></tr>\n", join( '</td><td>', $rowVal ) );
		  	};
		  	$i++;
		}
		$rv .= "</table>\n";
		return( $rv );
	}

	function query_as_array( $query ){
		$rv = array();
		$this->query_init( $query );
		while( $row = $this->query_next() ){
			array_push( $rv, $row );
		};
		return( $rv );
	}
	function query_field_as_array( $query, $field ){
		$rv = array();
		$this->query_init( $query );
		while( $row = $this->query_next() ){
            if( isset( $row[ $field ] ) ){
                array_push( $rv, $row[ $field ] );
            }else{
                array_push( $rv, NULL );
            }
		};
		return( $rv );
	}
	function query_first_row( $query ){
		$this->query_init( $query );
        $rv = $this->query_next();
        $this->query_close();
        return $rv;
	}

    function log(){
        
        $args = func_get_args();
        $tag = array_shift( $args );
        $fmt = array_shift( $args );

        $msg = vsprintf( $fmt, $args );
        if( $this->debug ){
            $bt = debug_backtrace();
            foreach( $bt as $frame ){
                #if( isset( $frame['class'] ) && $frame['class'] != 'sql_helper' ){
                printf( '  %s[%s] %s.%s'.PHP_EOL, basename($frame['file']), $frame['line'], $frame['class'], $frame['function'] );
                #}
            }
        }
        
        printf( "%s:%.3f: %s".PHP_EOL, $tag, microtime(true)-$this->start_ts, $msg );
    }
    
	function query_init( $query ){
		$this->current_query_str = $query; // for ref
		$this->lasterror = NULL;
        if( $this->verbose ){
            $this->log('EXECUTE', $query );
        }
		$this->current_query = $this->connection->query( $query );
        if( ! $this->current_query ){
			$this->lasterror = $this->connection->error;
            if( $this->verbose ){
                $this->log('ERROR', $this->connection->error );
            }
		};
		return( $this->current_query );
	}
	function query_next(){
		$rv = NULL;
		if( $this->current_query ){
			$rv = $this->current_query->fetch_array( MYSQLI_ASSOC );
			if( ! $rv ){
				$this->current_query = NULL;
			}else{
				foreach( $rv as $k => $v ){
					if( is_string( $v ) ) {
						$rv[$k] = stripslashes( $v );
					};
				}
			}
		};
		return( $rv );
	}
    function query_close(){
        if( $this->current_query ){
            $this->current_query->close();
            $this->current_query = NULL;
        }
    }



    //
    //
    // Update and modify data
    //
    //
    //
    function create_if_required($table, $fields, $drop = false){
        if( $drop ){
            $this->execute_query( sprintf( 'drop table if exists %s', $table ) );
        }
        if( $this->table_exists( $table ) ){
            return;
        }
        $fieldsdef = [];
        $query = sprintf('create table if not exists %s (', $table);
        foreach ($fields as $field => $type) {
            array_push($fieldsdef, "`{$field}` {$type}");
        }
        $query .= implode(', ', $fieldsdef);
        $query .= ')';
        if ($drop) {
            $query = sprintf('drop table if exists %s; %s', $table, $query);
        }
        $this->execute_query($query);

    }
	function create_or_alter( $table, $defs, $rebuild = false, $temporary = false ){
        $this->init_tableInfo();
        $create = false;
        if( isset( $this->tableInfo[ $table ] ) ) {
            if( $rebuild == true  ){
                $query = sprintf( 'DROP TABLE `%s`', $table );
                $this->execute_query( $query );
                $create = true;
            };
        }else{
            $create = true;
        }

        if( $create ){
            $fulldefs = array();
            foreach( $defs as $col => $def ){
                array_push( $fulldefs, sprintf( '%s %s', $col, $def ) );
            }
            if( $temporary ){
                $query = sprintf( 'CREATE TEMPORARY TABLE `%s` (%s) DEFAULT CHARSET=utf8', $table, join( ',', $fulldefs ) );
            }else{
                $query = sprintf( 'CREATE TABLE `%s` (%s) ENGINE=INNODB DEFAULT CHARSET=utf8', $table, join( ',', $fulldefs ) );
            }
            $this->execute_query( $query );
        }else{
            foreach( $defs as $col => $def ){
                if( isset( $this->tableInfo[ $table ][ $col ] ) ){
                    $existing = strtoupper( $this->tableInfo[ $table ][ $col ] );
                    $candidate = strtoupper( str_replace( ' PRIMARY KEY', '', $def ) );
                    $candidate = strtoupper( str_replace( ' AUTO_INCREMENT', '', $candidate ) );
                    if( $existing != $candidate ){
                        if( $this->verbose ){
                            $this->log( 'INFO', "%s.%s: [%s] != [%s]", $table, $col, $existing, $candidate );
                        }
                        $query = sprintf( 'ALTER TABLE `%s` CHANGE COLUMN `%s` `%s` %s', $table, $col, $col, $candidate );
                        $this->execute_query( $query );
                    }
                }else{
                    $query = sprintf( 'ALTER TABLE `%s` ADD COLUMN `%s` %s', $table, $col, $def );
                    $this->execute_query( $query );
                }
            }
        }
        $this->init_tableInfo( true ); //reload fields as it could have changed

	}
    function insert_or_update($table, $row, $id_array = array()){
        $sql = sprintf( 'INSERT INTO %s (', $table );
        $fields = [];
        $values = [];
        $holders = [];
        $updatefields = [];
        $updateholders = [];
        $updatevalues = [];
        $updatetypes = '';
        $types = '';
        foreach ($row as $field => $value) {
            $onevalue = $value;
            $onefield = $field;
            $oneholder = '?';
            $onetype = 's';
            if (is_int($value)) {
                $onetype = 'i';
            } else if (is_float($value)) {
                $onetype = 'd';
            } else if( $value instanceof DateTime ){
                $onetype = 'i';
                $oneholder = 'FROM_UNIXTIME(?)';
                $onevalue = $value->getTimestamp();
            } 
            array_push($fields, $onefield);
            array_push($values, $onevalue);
            array_push($holders, $oneholder);
            $types .= $onetype;
            if( !in_array( $field, $id_array ) ){
                $updatetypes .= $onetype;
                array_push($updatefields, sprintf( '%s = %s', $onefield, $oneholder ) );
                array_push($updatevalues, $onevalue);
                array_push($updateholders, $oneholder);
            }
        }
        $sql .= implode(', ', $fields);
        $sql .= ') VALUES (';
        $sql .= implode(', ', $holders);
        $sql .= ') ON DUPLICATE KEY UPDATE ';
        $sql .= implode(', ', $updatefields);
        $stmt = $this->connection->prepare($sql);
        if( $this->verbose ){
            print( sprintf( '<pre>%s</pre>', $sql ) );
        }
        $allvalues = array_merge( $values, $updatevalues );
        $stmt->bind_param($types.$updatetypes, ...$allvalues);
        $stmt->execute();
        $stmt->close();
        if( $this->connection->error ){
            printf( 'ERROR: %s' . PHP_EOL, $this->db->error );
        }
    }


    function insert_id() {
        return $this->connection->insert_id;
    }
	function execute_query( $query ){
		$result = true;
		if( $this->readOnly ){
            $this->log('READONLY', $query );
		}else{
			if( $this->verbose ){
                if( strlen( $query ) > 256 ){
                    $this->log('EXECUTE', '%s [...] %s', substr( $query, 0, 128 ), substr( $query, strlen( $query ) - 128 ) );
                }else{
                    $this->log('EXECUTE', '%s', $query );
                }
			};
			$this->current_query_str = $query;
			$result = $this->connection->query( $query );
			if( ! $result ) {
				$this->lasterror = $this->connection->error;
				if( $this->verbose ){
                    $this->log('ERROR', $this->lasterror );
				}
			};
		}
		return( $result );
	}

	function ensure_field( $db, $field, $def ){
		if( !$this->query_init( sprintf('select %s from %s', $field, $db ) ) ){
			$this->execute_query( sprintf( 'ALTER TABLE %s ADD %s %s', $db, $field, $def ) );
		}
	}


    //
    //
    // Helper to query info about data
    //
    //
	function min_value( $table, $field, $where ="" ){
		$maxfield = sprintf( "min(%s)", $field );
		$query = sprintf( "SELECT %s FROM %s %s LIMIT 1", $maxfield, $table, $where ) ;
		$res = $this->query_first_row( $query );
		return( $res[ $maxfield ] );
	}
	function max_value( $table, $field, $where ="" ){
		$maxfield = sprintf( "max(%s)", $field );
		$query = sprintf( "SELECT %s FROM %s %s LIMIT 1", $maxfield, $table, $where ) ;
		$res = $this->query_first_row( $query );
		return( $res[ $maxfield ] );
	}
	function count_rows( $table, $where = "" ){
		$countfield = "count(*)";
		$query = sprintf( "SELECT %s FROM %s %s LIMIT 1", $countfield, $table, $where ) ;
		$res = $this->query_first_row( $query );
		return( $res[ $countfield ] );
	}
	function table_exists( $table ){
        $rv = false;
		$query = sprintf( "SHOW TABLE STATUS like '%s'", $table );
		$stmt = $this->connection->prepare( $query );
        if( $this->verbose ){
            $this->log( "EXECUTED", $query );
        }
        if( $stmt ){
            $stmt->execute();
            $stmt->store_result();
            $rv = $stmt->num_rows()==1;
            $stmt->close();
        }else{
            if( $this->verbose ){
                $this->log( "ERROR", $this->connection->error );
            }
        }
        return $rv;
	}
};

if( is_null(sql_helper::$shared) ){
    sql_helper::$shared = new sql_helper();
}
