<?php
include_once( '../php/autoload.php' );

// Array with language codes corresponding to the country codes
// Array with language codes corresponding to the country codes
$languages_codes = array(
    'en' => ['US', 'GB', 'AU', 'CA', 'NZ'],
    'fr' => ['FR', 'BE', 'CA', 'CH', 'LU', 'MC', 'SN', 'TD', 'TG', 'TN', 'YT'],
    'de' => ['DE', 'AT', 'CH', 'LI', 'LU', 'BE'], // German-speaking countries
    'es' => ['ES', 'MX', 'GT', 'HN', 'SV', 'NI', 'CR', 'PA', 'VE', 'CO', 'EC', 'PE', 'BO', 'PY', 'UY', 'AR', 'PR', 'CU', 'DO', 'CL'] // Spanish-speaking countries
);

$languages_text = array(
    'en' => 'English',
    'fr' => 'Français',
    'de' => 'Deutsch',
    'es' => 'Español'
);

class Label {
    public BoardingPass $boardingPass;
    public string $language;

    function __construct(BoardingPass $boardingPass, string $language) {
        $this->boardingPass = $boardingPass;
        $this->language = $language;
    }
    function for($string, $uppercase = true) {
        if($uppercase) {
            print(strtoupper($this->boardingPass->localString($this->language, $string)));
        } else {
            print($this->boardingPass->localString($this->language, $string));
        }
    }
}

function language_has_disclaimer($language){
    if( file_exists("disclaimer_{$language}.html") ){
        return true;
    }
    return false;
}
// get language based on users choice or IP address
function get_chosen_language($languages_codes,$default_language='en'){
    if(isset($_GET['lang'])){
        $lang = $_GET['lang'];
    }else{
        $lang = substr($_SERVER['HTTP_ACCEPT_LANGUAGE'], 0, 2);
    }
    if(language_has_disclaimer($lang)){
        return $lang;
    }
    // get country code for the current IP address using ipwhois
    $ip = $_SERVER['REMOTE_ADDR'];
    $ipwhois = json_decode(file_get_contents("http://ipwho.is/{$ip}"));
    if(isset($ipwhois->country_code)){
        $country = $ipwhois->country_code;


        // check if the country code is in the array
        foreach($languages_codes as $key => $value){
            if(in_array($country,$value)){
                return $key;
            }
        }
    }
    return $default_language;
}

$chosen_language = get_chosen_language($languages_codes);
$disclaimer_file = "disclaimer_{$chosen_language}.html";

$query = [ 'lang' => $chosen_language ];

$current_url = $_SERVER['REQUEST_URI'];
$parsedUrl = parse_url($current_url);
$rootPath = null;
$rootPathComponents = [];

if(isset($parsedUrl['path'])){
    $pathComponents = explode('/',$parsedUrl['path'] );
    // if the path is /pages/boardingpass.php then we need to change it to /api/boardingPass.php
    // find the index of the pages folder
    $rootIndex = array_search('pages',$pathComponents);

    if($rootIndex !== false) {
        $rootPathComponents = array_slice($pathComponents,0,$rootIndex);
        $rootPath = implode('/',$rootPathComponents);
    }
}
if(is_null($rootPath)){
    http_response_code(500);
    die("Could not find the root path");
}

$get_pass = false;
$boardingPass = null;
$label = null;
if( isset($_GET['ticket']) && preg_match('/^[a-zA-Z0-9]+/',$_GET['ticket']) ){
    $pass_identifier = $_GET['ticket'];
    $ticket = MyFlyFunDb::$shared->directGetTicket($pass_identifier);
    if($ticket){
        $boardingPass = new BoardingPass($ticket);
        $label = new Label($boardingPass, $chosen_language);
        $query['ticket'] = $pass_identifier;
        $pathComponents = $rootPathComponents;
        $pathComponents[] = 'api';
        $pathComponents[] = 'boardingPass';
        $pathComponents[] = $pass_identifier;
        $path = implode('/',$pathComponents);
        $pass_url = $path;
        $airlineName = Airline::$current->airline_name;
        $get_pass = true;
        $passBackgroundColor = Airline::$current->settings()->backgroundColor();
        $passForegroundColor = Airline::$current->settings()->foregroundColor();
        $passLabelColor = Airline::$current->settings()->labelColor();
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>
<?php
if( $get_pass ){
    print("{$ticket->passenger->formattedName}'s {$airlineName} Fly Fun Boarding Pass");
}else{
    print("Fly Fun Boarding Pass Disclaimer");
}
?>
</title>

<style>
body {
  font-family: Arial, sans-serif;
  line-height: 1.6;
  margin: 20px;
}

.disclaimer {
  background-color: #f1f1f1;
  border-radius: 5px;
  padding: 20px;
  margin-bottom: 20px;
}
.category {
    font-weight: bold;
}
.language-switcher {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.language-switcher .logo {
    width: 100px;
    margin-right: 20px;
}
.language-buttons a {
    background-color: #f1f1f1;
    border-radius: 5px;
    padding: 10px;
    margin: 0 10px;
    text-decoration: none;
    color: #000;
}

.language-buttons a:hover {
    background-color: #ddd;
}

.logo-text {
    font-size: 2rem;
    font-weight: bold;
}

.logo-container {
    display: flex;
    align-items: center;
}

h2 {
  margin-bottom: 10px;
}

form {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
label {
    display: flex;
    align-items: center;
    justify-content: center;
}
#submit-link {
    margin-top: 10px;
    opacity: 1.0;
}

.boarding-section {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
}
.boarding-pass {
    border-radius: 12px;
    background-color: transparent;
    width: 350px;
    overflow: hidden; /* Add this line */
}

.boarding-header {
    background-color: <?php print($passBackgroundColor); ?>;
    padding: 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top-left-radius: 12px; /* Add this line */
    border-top-right-radius: 12px; /* Add this line */
    border-bottom-left-radius: 9px; /* Add this line */
    border-bottom-right-radius: 9px; /* Add this line */
    position: relative;
    z-index: 1;
    box-shadow: 0px 2px 10px rgba(0, 0, 0, 0.2);
    display: flex;
    flex-direction: column;
}

.boarding-body {
    padding: 10px;
    background-color: <?php print($passBackgroundColor); ?>;
    border-top-left-radius: 9px; /* Add this line */
    border-top-right-radius: 9px; /* Add this line */
    position: relative;
    z-index: 1;
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;

}

.boarding-qrcode {
    display: flex;
    background-color: <?php print($passBackgroundColor); ?>;
    justify-content: center;
    align-items: center;
    padding: 20px;
    box-shadow: 0px 2px 10px rgba(0, 0, 0, 0.2);
}

.header-row-1 {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
}

.header-row-2 {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 10px;
    font-size: 24px;
    width: 100%;
}

.flight-info {
    display: flex;
    gap: 10px;
}

.airline-name {
    font-size: 18px;
    font-weight: bold;
    color: <?php print($passForegroundColor); ?>;
}

.plane-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-grow: 1;
}

.plane-icon img {
    width: 40px;
    height: 40px;
}

.label {
    display: block;
    text-transform: uppercase;
    font-size: 10px;
    color: <?php print($passLabelColor); ?>;
}

.value {
    font-size: 14px;
    font-weight: bold;
    color: <?php print($passForegroundColor); ?>;
}

.value-large {
    font-size: 24px;
    font-weight: bold;
    color: <?php print($passForegroundColor); ?>;
}

.info-column {
    display: flex;
    flex-direction: column;
    box-sizing: border-box;
    padding: 10px;
    flex-basis: 50%;
}


.logo {
    width: 50px;
    height: 50px;
}
</style>
<script src="<?php print($rootPath); ?>/js/qrcode.min.js"></script>
</head>
<body>

<div class="language-switcher">
    <div class="logo-container">
    <img src="<?php print($rootPath);?>/images/logo.png" alt="logo" width="100">
        <span class="logo-text">Fly Fun</span>
    </div>
    <div class="language-buttons">
        <?php
        foreach($languages_text as $key => $value){
            $query['lang'] = $key;
            $url = $_SERVER['PHP_SELF'] . '?' . http_build_query($query);
            echo "<a href=\"{$url}\">{$value}</a>";
        }
        ?>
    </div>
</div>

<?php
if($get_pass) {
    include('walletPass.php');
    $img_url = "{$rootPath}/images/AddToApple/{$chosen_language}/badge.svg" ;
?>
<div class="acknowledge">
<form>
  <label>
    <input type="checkbox" id="agree-checkbox" value="1" checked>
<?php $label->for('I agree to the terms and conditions below', false); ?>
  </label>
  <a id="submit-link" href="<?php echo $pass_url; ?>" download>
  <img id="submit-img" src="<?php echo $img_url; ?>" alt="Add to Apple Wallet" width="100">
  </a>
</form>
<script>
    const agreeCheckbox = document.getElementById('agree-checkbox');
    const submitLink = document.getElementById('submit-link');
    const submitImg = document.getElementById('submit-img');

    agreeCheckbox.addEventListener('change', function() {
        if (agreeCheckbox.checked) {
          submitLink.style.opacity = 1;
          submitImg.style.opacity = 1;
          submitLink.href = "<?php echo $pass_url; ?>";
        } else {
          submitLink.style.opacity = 0.5;
          submitImg.style.opacity = 0.5;
          
          submitLink.removeAttribute('href');
        }
    });
</script>
<?php
}
?>

</div>
<div class="disclaimer">
<?php
if( file_exists($disclaimer_file) ){
    include($disclaimer_file);
}else{
    echo "No disclaimer available for this language {$chosen_language} {$disclaimer_file}.";
}
?>
</div>

