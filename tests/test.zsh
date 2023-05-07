samples="app/flyfunboarding/Preview Content"


curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_airline.json https://${baseurl}/airline/create
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/keys

curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_aircraft.json "https://${baseurl}/airline/${airline}/aircraft/create"
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_aircraft_2.json https://${baseurl}/airline/${airline}/aircraft/create

curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/aircraft/list
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/aircraft/${aircraft}
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/aircraft/${aircraft}/flights

curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_passenger.json https://${baseurl}/airline/${airline}/passenger/create
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_passenger_2.json https://${baseurl}/airline/${airline}/passenger/create

curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/passenger/list
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/passenger/${passenger}
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/passenger/${passenger}/tickets


curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_flight.json "https://${baseurl}/airline/${airline}/flight/plan/${aircraft}"
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/flight/list
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/flight/${flight}
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/flight/${flight}/tickets
curl -X DELETE                                   -H ${auth}                                 https://${baseurl}/airline/${airline}/flight/${flight}
jq '.[0]' samples/sample_flights.json | curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @- "https://${baseurl}/airline/${airline}/flight/check/${flight}"

curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_ticket.json "https://${baseurl}/airline/${airline}/ticket/issue/${flight}/${passenger}"
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/ticket/list
curl                                             -H ${auth}                                 https://${baseurl}/airline/${airline}/ticket/${ticket}
curl -X DELETE                                   -H ${auth}                                 https://${baseurl}/airline/${airline}/ticket/${ticket}
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_validate.json "https://${baseurl}/airline/${airline}/ticket/verify"

curl                                                                                        "https://${baseurl}/boardingpass/${ticket}?debug"

