<?php
if( isset($ticket)) {
?>
<div class="boarding-section">
<div class="boarding-pass">
    <div class="boarding-header">
        <div class="header-row-1">
            <img class="logo" src="../images/logo.png" alt="Logo" />
            <span class="airline-name"><?php print(Airline::$current->airline_name)?></span>
            <div class="flight-info">
                <div>
                    <span class="label">FLIGHT</span>
                    <span class="value"><?php print($ticket->flight->flightNumber)?></span>
                </div>
                <div>
                    <span class="label">SEAT</span>
                    <span class="value"><?php print($ticket->seatNumber) ?></span>
                </div>
            </div>
        </div>
        <div class="header-row-2">
            <div>
            <span class="label"><?php print($ticket->flight->origin->fitName(20))?></span>
            <span class="value-large"><?php print($ticket->flight->origin->getIcao())?></span>
            </div>
            <div class="plane-icon"><img src="../images/airplane@2x.png" alt="plane icon"></div>
            <div>
            <span class="label"><?php print($ticket->flight->destination->fitName(20))?></span>
            <span class="value-large"><?php print($ticket->flight->destination->getIcao())?></span>
            </div>
        </div>
    </div>
    <div class="boarding-body">
        <div class="info-column">
            <div>
                <span class="label">DATE</span>
                <span class="value">2023-03-30</span>
            </div>
            <div>
                <span class="label">PASSENGER</span>
                <span class="value"><?php print($ticket->passenger->formattedName)?></span>
            </div>
        </div>
        <div class="info-column">
            <div>
                <span class="label">GATE</span>
                <span class="value"><?php print($ticket->flight->gate)?></span>
            </div>
        </div>
    </div>
    <div class="boarding-qrcode">
        <div id="signature-qrcode"></div>
            <script>
            var qrData = <?php echo(json_encode($ticket->signature()))?>;
            var qrCodeElement = document.getElementById("signature-qrcode");

            var qrCode = new QRCode(qrCodeElement, {
                text: qrData,
                width: 128,
                height: 128,
                colorDark: "#000000",
                colorLight: "#ffffff",
                correctLevel: QRCode.CorrectLevel.H
            });

            </script>
        </div>
    </div>
</div>

<?php
}
