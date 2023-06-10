<?php
if( isset($ticket) && isset($label)) {
?>
<div class="boarding-section">
<div class="boarding-pass">
    <div class="boarding-header">
        <div class="header-row-1">
        <img class="logo" src="<?php print($rootPath); ?>/images/logo.png" alt="Logo" />
            <span class="airline-name"><?php print(Airline::$current->airline_name)?></span>
            <div class="flight-info">
                <div>
                    <?php if( $ticket->flight->hasFlightNumber()) { ?>
                    <span class="label"><?php $label->for('Flight')?></span>
                    <span class="value"><?php print($ticket->flight->flightNumber)?></span>
                    <?php } else { ?>
                    <span class="label"><?php $label->for('Aircraft')?></span>
                    <span class="value"><?php print($ticket->flight->aircraft->registration)?></span>
                    <?php } ?>
                </div>
                <div>
                <span class="label"><?php $label->for('Seat')?></span>
                    <span class="value"><?php print($ticket->seatNumber) ?></span>
                </div>
            </div>
        </div>
        <div class="header-row-2">
            <div>
            <span class="label"><?php print($ticket->flight->origin->fitName(20))?></span>
            <span class="value-large"><?php print($ticket->flight->origin->getIcao())?></span>
            </div>
            <div class="plane-icon"><img src="<?php print($rootPath);?>/images/airplane@2x.png" alt="plane icon"></div>
            <div>
            <span class="label"><?php print($ticket->flight->destination->fitName(20))?></span>
            <span class="value-large"><?php print($ticket->flight->destination->getIcao())?></span>
            </div>
        </div>
    </div>
    <div class="boarding-body">
        <div class="info-column">
            <div>
            <span class="label"><?php $label->for('Departs')?></span>
                <span class="value"><?php print($ticket->flight->formatScheduledDepartureDate())?></span>
            </div>
            <div>
            <span class="label"><?php $label->for('Passenger')?></span>
                <span class="value"><?php print($ticket->passenger->formattedName)?></span>
            </div>
        </div>
        <div class="info-column">
            <?php if( Airline::$current->settings()->customLabelEnabled()) { ?>
            <div>  
            <span class="label"><?php $label->for(Airline::$current->settings()->customLabel())?></span>
                <span class="value"><?php print($ticket->customLabelValue)?></span>
            </div>
            <?php }elseif( $ticket->flight->hasFlightNumber()) { ?>
            <div>  
            <span class="label"><?php $label->for('Aircraft')?></span>
                <span class="value"><?php print($ticket->flight->aircraft->registration)?></span>
            </div>
            <?php } ?>
            <div>
            <span class="label"><?php $label->for('Gate')?></span>
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
                text: JSON.stringify(qrData),
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
