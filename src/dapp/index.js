
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })


        DOM.elid('purchase-flight-insurance').addEventListener('click', () => {
            console.log("purchase-flight-insurance");
            // Passenger Airline Choice
            // Passengers can choose from a fixed list of flight numbers and departure that are defined in the Dapp client
            let flight = DOM.elid('flight-number').value;

            // Passenger Payment
            // Passengers may pay up to 1 ether for purchasing flight insurance.
            let ethValue = DOM.elid('eth-value').value;
            
            console.log("purchase-flight-insurance",flight, ethValue);

            contract.purchaseFlightInsurance(flight, ethValue, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Purchase Flight Insurance', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // claim repayment and withdraw
        DOM.elid('claim-repayment').addEventListener('click', () => {
            const flight = DOM.elid('flight-address').value;
            // Passenger Repayment
            // If flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid
            
            // Passenger Withdraw
            // Passenger can withdraw any funds owed to them as a result of receiving credit for insurance payout

            // FIXME: ??????????????????????
            // Insurance Payouts
            // Insurance payouts are not sent directly to passenger’s wallet

            contract.claimRepayment(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Claim Repayment', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })
    });
})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







