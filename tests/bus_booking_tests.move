#[test_only]
module bus_booking::test_picture {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::test_utils::{assert_eq};
    use sui::sui::SUI;
    use sui::coin::{mint_for_testing};
    use sui::coin::{Self, Coin}; 
    use std::string::{Self};

    use bus_booking::helpers::{init_test_helper};
    use bus_booking::bus_booking::{Self as bk, Bus, BusCap, User, BookedSeat};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_create_bus() {
        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        // Create an kiosk for marketplace
        next_tx(scenario, TEST_ADDRESS1);
        {
            let operator = TEST_ADDRESS1;
            let name = b"asd".to_string();
            let details = b"asd".to_string();
            let price: u64 = 1_000_000_000;
            let total_seats: u64 = 20;

            bk::create_bus(operator, name, details, price, total_seats, ts::ctx(scenario))
        };

        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut self = ts::take_shared<Bus>(scenario);
            let user_name = b"asd".to_string();
            let user_type: u8 = 1;
            let public_key = b"asd".to_string();

            let user = bk::register_user(&mut self, user_name, user_type, public_key, ts::ctx(scenario));
            transfer::public_transfer(user, TEST_ADDRESS2);
            ts::return_shared(self);
        };

        next_tx(scenario, TEST_ADDRESS2);
        {
            let mut self = ts::take_shared<Bus>(scenario);
            let mut payment_coin = mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));
        
            bk::book_seat(&mut self, &mut payment_coin, ts::ctx(scenario));

            transfer::public_transfer(payment_coin, TEST_ADDRESS2);
            ts::return_shared(self);
        };

        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut self = ts::take_shared<Bus>(scenario);
            let cap = ts::take_from_sender<BusCap>(scenario);
        
            bk::withdraw_funds(&cap,&mut self, 1_000_000_000, ts::ctx(scenario));

            ts::return_shared(self);
            ts::return_to_sender(scenario, cap)
        };
  
        ts::end(scenario_test);
    }
}