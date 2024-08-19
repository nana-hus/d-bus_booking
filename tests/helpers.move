#[test_only]
module bus_booking::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
 
    use std::string::{Self};

    const ADMIN: address = @0xA;
    public fun init_test_helper() : ts::Scenario{

       let mut scenario_val = ts::begin(ADMIN);
       let scenario = &mut scenario_val;

       scenario_val
    }

}