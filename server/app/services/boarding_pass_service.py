"""
Boarding Pass service for PKPass generation.

Matches PHP BoardingPass class behavior.
Uses passes-rs-py library for PKPass generation.
"""
import json
import tempfile
from pathlib import Path
from typing import Optional
import logging

from app.config import settings
from app.models.ticket import Ticket
from app.models.settings import Settings
from app.models.airline import Airline
from app.services.signature_service import SignatureService

logger = logging.getLogger(__name__)


class BoardingPassService:
    """
    Service for generating Apple Wallet PKPass files.
    
    Matches PHP BoardingPass class functionality.
    """

    def __init__(self, ticket: Ticket, airline: Optional[Airline] = None, airline_settings: Optional[Settings] = None):
        """
        Initialize boarding pass service.
        
        Args:
            ticket: Ticket object
            airline: Airline object (optional, for settings)
            airline_settings: Settings object (optional, for colors)
        """
        self.ticket = ticket
        self.passenger = ticket.passenger
        self.flight = ticket.flight
        self.airline = airline
        self.airline_settings = airline_settings

    def locale_strings(self, language: str) -> dict[str, str]:
        """
        Get localized strings for a language.
        
        Matches PHP: BoardingPass->localeStrings()
        """
        defs = {
            'fr': {
                'Flight': 'Vol',
                'Aircraft': 'Avion',
                'Gate': 'Porte',
                'Departs': 'Départ',
                'Arrives': 'Arrivée',
                'Passenger': 'Passager',
                'Seat': 'Siège',
                'I agree to the terms and conditions below': 'J\'accepte les termes et conditions ci-dessous',
            },
            'en': {
                'Flight': 'Flight',
                'Aircraft': 'Aircraft',
                'Gate': 'Gate',
                'Departs': 'Departs',
                'Arrives': 'Arrives',
                'Passenger': 'Passenger',
                'Seat': 'Seat',
                'I agree to the terms and conditions below': 'I agree to the terms and conditions below',
            },
            'de': {
                'Flight': 'Flug',
                'Aircraft': 'Flugzeug',
                'Gate': 'Tor',
                'Departs': 'Abflug',
                'Arrives': 'Ankunft',
                'Passenger': 'Passagier',
                'Seat': 'Sitz',
                'I agree to the terms and conditions below': 'Ich stimme den unten stehenden Bedingungen zu',
            },
            'es': {
                'Flight': 'Vuelo',
                'Aircraft': 'Avión',
                'Gate': 'Puerta',
                'Departs': 'Sale',
                'Arrives': 'Llega',
                'Passenger': 'Pasajero',
                'Seat': 'Asiento',
                'I agree to the terms and conditions below': 'Acepto los términos y condiciones a continuación',
            },
        }
        return defs.get(language, {})

    def text_field(self, key: str, label: str, value: str) -> dict:
        """
        Create a text field for PKPass.
        
        Matches PHP: BoardingPass->textField()
        """
        return {
            'key': key,
            'label': label,
            'value': value,
        }

    def boarding_pass_data(self) -> dict:
        """
        Build boarding pass data structure.
        
        Matches PHP: BoardingPass->boardingPassData()
        """
        boardingpass = {'transitType': 'PKTransitTypeAir'}
        
        # Header fields
        boardingpass['headerFields'] = [
            self.text_field('seat', 'Seat', self.ticket.seat_number),
        ]
        
        if self.flight.has_flight_number():
            boardingpass['headerFields'].append(
                self.text_field('flight-number', 'Flight', self.flight.flight_number)
            )
        else:
            boardingpass['headerFields'].append(
                self.text_field('flight-number', 'Aircraft', self.flight.aircraft.registration)
            )
        
        # Primary fields
        boardingpass['primaryFields'] = [
            self.text_field('origin', self.flight.origin.fit_name(20), self.flight.origin.icao),
            self.text_field('destination', self.flight.destination.fit_name(20), self.flight.destination.icao),
        ]
        
        # Secondary fields
        boardingpass['secondaryFields'] = [
            self.text_field('passenger-name', 'Passenger', self.passenger.formatted_name or ''),
            self.text_field('gate', 'Gate', self.flight.gate),
        ]
        
        # Auxiliary fields
        boardingpass['auxiliaryFields'] = [
            self.text_field('date', 'Departs', self.flight.format_scheduled_departure_date()),
        ]
        
        has_custom = self.ticket.has_custom_label(self.airline_settings)
        if has_custom and self.airline_settings:
            boardingpass['auxiliaryFields'].append(
                self.text_field('custom-label', self.airline_settings.custom_label, self.ticket.custom_label_value)
            )
        
        if not has_custom and self.flight.has_flight_number():
            boardingpass['auxiliaryFields'].append(
                self.text_field('aircraft', 'Aircraft', self.flight.aircraft.registration)
            )
        
        # Back fields
        boardingpass['backFields'] = [
            self.text_field('passenger-name', 'Passenger', self.passenger.formatted_name or ''),
        ]
        
        # Add airport information to back fields
        origin_info = self.flight.origin.get_info()
        destination_info = self.flight.destination.get_info()
        
        for which, info in [('origin', origin_info), ('destination', destination_info)]:
            if info:
                # Map URL
                map_url = self.flight.origin.get_map_url() if which == 'origin' else self.flight.destination.get_map_url()
                if map_url:
                    label = 'Origin Airport Location' if which == 'origin' else 'Destination Airport Location'
                    boardingpass['backFields'].append(
                        self.text_field(f'{which}-map-url', label, map_url)
                    )
                
                # Airport details
                for key in ['name', 'municipality', 'iso_country', 'iata_code', 'home_link', 'wikipedia_link']:
                    if key in info and info[key]:
                        # Replace _ with space and capitalize
                        label = f"{which.title()} Airport {key.replace('_', ' ').title()}"
                        field_key = f"{which}-{key.replace('_', '-')}"
                        boardingpass['backFields'].append(
                            self.text_field(field_key, label, str(info[key]))
                        )
        
        # Locations
        locations = self.location_data()
        if locations:
            boardingpass['locations'] = locations
        
        return boardingpass

    def location_data(self) -> list[dict]:
        """
        Get location data for PKPass.
        
        Matches PHP: BoardingPass->locationData()
        """
        locations = []
        
        origin_location = self.flight.origin.get_location()
        if origin_location:
            origin_location['relevantText'] = f'Welcome to {self.flight.origin.get_name() or self.flight.origin.icao}'
            locations.append(origin_location)
        
        if self.flight.destination.icao != self.flight.origin.icao:
            destination_location = self.flight.destination.get_location()
            if destination_location:
                destination_location['relevantText'] = f'Thank you for flying with us to {self.flight.destination.get_name() or self.flight.destination.icao}'
                locations.append(destination_location)
        
        return locations

    def get_barcode_data(self) -> dict:
        """
        Get barcode data for PKPass.
        
        Matches PHP: BoardingPass->getBarcodeData()
        """
        # Get signature service for the airline
        if self.airline:
            airline_data = self.airline.model_dump(by_alias=True)
            apple_identifier = airline_data.get('apple_identifier', '')
            signature_service = SignatureService(apple_identifier)
            payload = self.ticket.signature(signature_service)
        else:
            # Fallback if no airline
            payload = {
                'ticket': self.ticket.ticket_identifier,
                'signatureDigest': {}
            }
        
        return {
            'format': 'PKBarcodeFormatQR',
            'message': json.dumps(payload),
            'messageEncoding': 'iso-8859-1'
        }

    def get_pass_data(self) -> dict:
        """
        Get complete pass data structure.
        
        Matches PHP: BoardingPass->getPassData()
        """
        # Default values
        data = {
            'description': 'Boarding Pass',
            'formatVersion': 1,
            'organizationName': 'FlyFun Boarding Pass',
            'passTypeIdentifier': 'pass.net.ro-z.flyfunboardingpass',
            'serialNumber': self.ticket.ticket_identifier,
            'teamIdentifier': 'M7QSSF3624',
            'backgroundColor': 'rgb(189,144,71)',
            'foregroundColor': 'rgb(255,255,255)',
            'labelColor': 'rgb(255,255,255)',
            'logoText': 'FlyFun Airline',
            'relevantDate': self._format_relevant_date(),
        }
        
        # Override with airline settings if available
        if self.airline and self.airline_settings:
            airline_data = self.airline.model_dump(by_alias=True)
            data['logoText'] = airline_data.get('airline_name', 'FlyFun Airline')
            data['backgroundColor'] = self.airline_settings.background_color
            data['foregroundColor'] = self.airline_settings.foreground_color
            data['labelColor'] = self.airline_settings.label_color
        
        boardingpass = self.boarding_pass_data()
        data['boardingPass'] = boardingpass
        data['barcode'] = self.get_barcode_data()
        
        return data

    def create_pass(self, output_path: Optional[Path] = None) -> bytes:
        """
        Create PKPass file.
        
        Matches PHP: BoardingPass->createPass()
        
        Args:
            output_path: Optional path to save .pkpass file. If None, returns bytes.
        
        Returns:
            bytes of .pkpass file
        """
        from passes_rs_py import generate_pass
        
        pass_data = self.get_pass_data()
        
        # Create complete pass JSON string - passes-rs-py expects config as JSON string
        # Include all pass data fields
        pass_json = {
            'formatVersion': pass_data['formatVersion'],
            'passTypeIdentifier': pass_data['passTypeIdentifier'],
            'organizationName': pass_data['organizationName'],
            'teamIdentifier': pass_data['teamIdentifier'],
            'serialNumber': pass_data['serialNumber'],
            'description': pass_data['description'],
            'backgroundColor': pass_data['backgroundColor'],
            'foregroundColor': pass_data['foregroundColor'],
            'labelColor': pass_data['labelColor'],
            'logoText': pass_data['logoText'],
            'relevantDate': pass_data['relevantDate'],
            'boardingPass': pass_data['boardingPass'],
            'barcode': pass_data['barcode'],
        }
        pass_json_str = json.dumps(pass_json)
        
        # Handle certificate - passes-rs-py needs separate cert and key
        # If we have a P12, we need to extract cert and key
        cert_path = self._get_cert_path()
        key_path = self._get_key_path()
        
        # Image paths
        images_path = settings.IMAGES_PATH
        icon_path = images_path / 'icon.png' if (images_path / 'icon.png').exists() else None
        icon2x_path = images_path / 'icon@2x.png' if (images_path / 'icon@2x.png').exists() else None
        logo_path = images_path / 'logo.png' if (images_path / 'logo.png').exists() else None
        
        # Use temp file if no output path
        if output_path is None:
            with tempfile.NamedTemporaryFile(suffix='.pkpass', delete=False) as tmp:
                output_path = Path(tmp.name)
                tmp_path = output_path
        else:
            tmp_path = None
        
        try:
            # Generate pass - passes-rs-py expects config as JSON string
            generate_pass(
                config=pass_json_str,
                cert_path=str(cert_path),
                key_path=str(key_path),
                output_path=str(output_path),
                icon_path=str(icon_path) if icon_path else None,
                icon2x_path=str(icon2x_path) if icon2x_path else None,
                logo_path=str(logo_path) if logo_path else None,
            )
            
            # Read and return bytes
            with open(output_path, 'rb') as f:
                pkpass_bytes = f.read()
            
            # Clean up temp file if we created one
            if tmp_path and tmp_path.exists():
                tmp_path.unlink()
            
            return pkpass_bytes
            
        except Exception as e:
            logger.error(f"Error creating PKPass: {e}")
            if tmp_path and tmp_path.exists():
                tmp_path.unlink()
            raise

    def _get_cert_path(self) -> Path:
        """Get certificate path, extracting from P12 if needed."""
        cert_path = settings.CERTIFICATE_PATH
        
        # If it's a .p12 file, we need to extract the certificate
        if cert_path.suffix.lower() == '.p12':
            # Extract certificate from P12
            # This requires openssl or cryptography library
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.serialization import pkcs12
            
            try:
                with open(cert_path, 'rb') as f:
                    p12_data = f.read()
                
                # Load P12
                private_key, certificate, additional_certificates = pkcs12.load_key_and_certificates(
                    p12_data,
                    settings.CERTIFICATE_PASSWORD.encode() if settings.CERTIFICATE_PASSWORD else None
                )
                
                # Save certificate to temp file
                with tempfile.NamedTemporaryFile(mode='wb', suffix='.pem', delete=False) as tmp:
                    tmp.write(certificate.public_bytes(serialization.Encoding.PEM))
                    return Path(tmp.name)
            except Exception as e:
                logger.error(f"Error extracting certificate from P12: {e}")
                raise
        else:
            # Assume it's already a PEM certificate
            return cert_path

    def _format_relevant_date(self) -> str:
        """
        Format relevantDate for PKPass.
        
        Matches PHP: $this->flight->scheduledDepartureDate->format('Y-m-d\\TH:i:sP')
        Returns ISO 8601 format with timezone offset (e.g., '2024-06-19T08:00:00+01:00')
        """
        from datetime import timezone
        
        date = self.flight.scheduled_departure_date
        
        # Ensure timezone-aware
        if date.tzinfo is None:
            date = date.replace(tzinfo=timezone.utc)
        
        # Format: 'Y-m-d\TH:i:sP' (e.g., '2024-06-19T08:00:00+01:00')
        # Python's %z gives +0000, but we need +00:00 format
        offset = date.strftime('%z')
        if len(offset) == 5:
            # Convert +0000 to +00:00
            offset = f"{offset[:3]}:{offset[3:]}"
        
        return date.strftime('%Y-%m-%dT%H:%M:%S') + offset
    
    def _get_key_path(self) -> Path:
        """Get private key path, extracting from P12 if needed."""
        cert_path = settings.CERTIFICATE_PATH
        
        # If it's a .p12 file, we need to extract the key
        if cert_path.suffix.lower() == '.p12':
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.serialization import pkcs12
            
            try:
                with open(cert_path, 'rb') as f:
                    p12_data = f.read()
                
                # Load P12
                private_key, certificate, additional_certificates = pkcs12.load_key_and_certificates(
                    p12_data,
                    settings.CERTIFICATE_PASSWORD.encode() if settings.CERTIFICATE_PASSWORD else None
                )
                
                # Save private key to temp file
                with tempfile.NamedTemporaryFile(mode='wb', suffix='.pem', delete=False) as tmp:
                    tmp.write(private_key.private_bytes(
                        encoding=serialization.Encoding.PEM,
                        format=serialization.PrivateFormat.PKCS8,
                        encryption_algorithm=serialization.NoEncryption()
                    ))
                    return Path(tmp.name)
            except Exception as e:
                logger.error(f"Error extracting key from P12: {e}")
                raise
        else:
            # Assume key is in same directory with .key extension
            key_path = cert_path.parent / f"{cert_path.stem}.key"
            if not key_path.exists():
                # Try .pem extension
                key_path = cert_path.parent / f"{cert_path.stem}.pem"
            return key_path

