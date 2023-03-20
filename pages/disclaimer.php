<?php
// Array with language codes corresponding to the country codes

$languages_codes = array(
    'en' => ['US','GB','AU','CA','NZ'],
    'fr' => ['FR','BE','CA','CH','LU','MC','SN','TD','TG','TN','YT']
);

$languages_text = array( 
    'en' => 'English',
    'fr' => 'Français'
);

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


$get_pass = false;

$query = [ 'lang' => $chosen_language ];

if( isset($_GET['ticket']) && preg_match('/^[a-zA-Z0-9]+/',$_GET['ticket']) ){
    $pass_identifier = $_GET['ticket'];
    $query['ticket'] = $pass_identifier;
    $current_url = $_SERVER['REQUEST_URI'];
    $parsedUrl = parse_url($current_url);
    if(isset($parsedUrl['path'])){
        $path = $parsedUrl['path'];
        $path = str_replace('pages/disclaimer.php',"api/boardingPass/{$pass_identifier}",$path);
        $pass_url = $path;
        $get_pass = true;
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fly Fun Boarding Pass Disclaimer</title>
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
    opacity: 0.5;
}

</style>
</head>
<body>

<div class="language-switcher">
    <div class="logo-container">
    <img src="../images/logo.png" alt="logo" width="100">
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
    $img_url = "../images/AddToApple/{$chosen_language}/badge.svg" ;
?>
<div class="acknowledge">
<form>
  <label>
    <input type="checkbox" id="agree-checkbox">
    I agree to the terms and conditions
  </label>
  <a id="submit-link" href="#" download>
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

