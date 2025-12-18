samples="app/flyfunboarding/Preview Content"
HTTP=http


curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/db/setup


curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_airline.json ${HTTP}://${baseurl}/airline/create
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/keys

curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_aircraft.json "${HTTP}://${baseurl}/airline/${airline}/aircraft/create"
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_aircraft_2.json ${HTTP}://${baseurl}/airline/${airline}/aircraft/create

curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/aircraft/list
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/aircraft/${aircraft}
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/aircraft/${aircraft}/flights

curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_passenger.json ${HTTP}://${baseurl}/airline/${airline}/passenger/create
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_passenger_2.json ${HTTP}://${baseurl}/airline/${airline}/passenger/create

curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/passenger/list
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/passenger/${passenger}
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/passenger/${passenger}/tickets


curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_flight.json "${HTTP}://${baseurl}/airline/${airline}/flight/plan/${aircraft}"
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/flight/list
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/flight/${flight}
curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/flight/${flight}/tickets
curl -X DELETE                                   -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/flight/${flight}
jq '.[0]' samples/sample_flights.json | curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @- "${HTTP}://${baseurl}/airline/${airline}/flight/check/${flight}"

curl                                             -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/ticket/${ticket}
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @{samples}/sample_ticket_issue.json ${HTTP}://${baseurl}/airline/${airline}/ticket/issue/${flight}/${passenger}
curl -X DELETE                                   -H ${auth}                                 ${HTTP}://${baseurl}/airline/${airline}/ticket/${ticket}
curl -X POST -H 'Content-Type: application/json' -H ${auth} -d @${samples}/sample_validate.json "${HTTP}://${baseurl}/airline/${airline}/ticket/verify"

curl                                                                                        "${HTTP}://${baseurl}/boardingpass/${ticket}?debug"

