#[allow(unused_use,unused_variable,unused_const,lint(self_transfer),unused_field)]
module bus_booking::bus_booking {
    use sui::event;
    use sui::sui::SUI;
    use std::string::{String};
    use sui::coin::{Coin, value, split, put, take};
    use sui::object::new;
    use sui::balance::{Balance, zero, value as balance_value};
    use sui::tx_context::sender;
    use sui::table::{Self, Table};

    // Enum for more descriptive error handling
    const Error_Invalid_Amount: u64 = 2;
    const Error_Insufficient_Payment: u64 = 4;
    const Error_Invalid_Price: u64 = 6;
    const Error_Invalid_Seats: u64 = 7;
    const Error_BusNotListed: u64 = 8;
    const Error_NotOwner: u64 = 0;
    const Error_ReentrancyAttack: u64 = 10;

    // User struct definition
    public struct User has key, store {
        id: UID,
        associated_buses: Table<ID, bool>,  // Supports multiple bus associations
        user_name: String,
        user_type: u8,
        public_key: String,
    }

    // Bus struct definition
    public struct Bus has key, store {
        id: UID,
        bus_id: ID,
        passengers: Table<address, bool>,
        name: String,
        details: String,
        price: u64,
        total_seats: u64,
        available_seats: u64,
        operator: address,
        balance: Balance<SUI>,
        active: bool,  // Track if the bus is active or canceled
        dynamic_pricing_enabled: bool,  // Enables dynamic pricing
    }

    public struct BusCap has key {
        id: UID,
        `for`: ID,
    }

    // BookedSeat struct definition
    public struct BookedSeat has key {
        id: UID,
        bus_id: ID,
        passenger: address,
    }

    // DriverProfile struct definition
    public struct DriverProfile has key {
        id: UID,
        bus: ID,
        rates: Table<address, u64>,
        driver_name: String,
        routes: vector<String>,
    }

    // Events Definitions

    // BusCreated event
    public struct BusCreated has copy, drop {
        bus_id: ID,
        operator: address,
    }

    // SeatBooked event
    public struct SeatBooked has copy, drop {
        bus_id: ID,
        passenger: address,
        seat_number: u64,  // Track seat number for better management
    }

    // BusCompleted event
    public struct BusCompleted has copy, drop {
        bus_id: ID,
        passenger: address,
    }

    // BusUpdated event
    public struct BusUpdated has copy, drop {
        bus_id: ID,
        new_details: String,
    }

    // BusUnlisted event
    public struct BusUnlisted has copy, drop {
        bus_id: ID,
    }

    // FundWithdrawal event
    public struct FundWithdrawal has copy, drop {
        amount: u64,
        recipient: address,
    }

    // DriverProfileCreated event
    public struct DriverProfileCreated has copy, drop {
        driver_id: u64,
        driver_name: String,
    }

    // DrivingServiceOffered event
    public struct DrivingServiceOffered has copy, drop {
        driver_id: u64,
        route_id: u64,
        rate: u64,
    }

    // DrivingSessionRequested event
    public struct DrivingSessionRequested has copy, drop {
        session_id: u64,
        driver_id: u64,
        passenger: address,
    }

    // DrivingSessionCompleted event
    public struct DrivingSessionCompleted has copy, drop {
        session_id: u64,
        driver_id: u64,
        passenger: address,
    }

    // DrivingServiceUpdated event
    public struct DrivingServiceUpdated has copy, drop {
        driver_id: u64,
        route_id: u64,
        rate: u64,
        available: bool,
    }

    // Function to register a new user
    public fun register_user(
        user_name: String,  // Username encoded as UTF-8 bytes
        user_type: u8,  // Type of user (e.g., passenger, driver)
        public_key: String,  // Public key of the user
        ctx: &mut TxContext  // Transaction context
    ): User {
        let user_id = new(ctx);
        let user = User {
            id: user_id,
            associated_buses: table::new(ctx),
            user_name: user_name,
            user_type: user_type,
            public_key: public_key,
        };

        event::emit(UserRegistered {  // Emit a new event for user registration
            user_id: object::id(&user),
            user_name: user.user_name.clone(),
        });

        transfer::share_object(user);
        user
    }

    // Function to create a new bus
    public fun create_bus(
        operator: address,  // Address of the bus operator
        name: String,  // Bus name encoded as UTF-8 bytes
        details: String,  // Bus details encoded as UTF-8 bytes
        price: u64,  // Price of a seat
        total_seats: u64,  // Total seats available
        enable_dynamic_pricing: bool,  // Enable dynamic pricing feature
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(price > 0, Error_Invalid_Price);  // Validate price is positive
        assert!(total_seats > 0, Error_Invalid_Seats);  // Validate total seats are positive

        let bus_uid = new(ctx);  // Generate unique ID for the bus
        let inner = object::uid_to_inner(&bus_uid);
        let bus = Bus {
            id: bus_uid,
            bus_id: inner,  // Initial bus ID (to be updated)
            passengers: table::new(ctx),
            name: name,
            details: details,
            price: price,
            total_seats: total_seats,
            available_seats: total_seats,
            operator: operator,
            balance: zero<SUI>(),  // Initialize balance for bus
            active: true,  // Bus is active upon creation
            dynamic_pricing_enabled: enable_dynamic_pricing,  // Set dynamic pricing flag
        };

        let cap = BusCap {
            id: new(ctx),
            `for`: inner,
        };
        transfer::transfer(cap, sender(ctx));
        transfer::share_object(bus);  // Share bus details
        event::emit(BusCreated {
            bus_id: inner,  // Placeholder for actual bus ID
            operator: operator,
        });
    }

    // Function to book a seat on a bus
    public fun book_seat(
        bus: &mut Bus,  // Reference to the bus to book a seat on
        payment_coin: &mut Coin<SUI>,  // Payment coin for booking
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(table::contains(&bus.passengers, ctx.sender()), Error_BusNotListed);  // Ensure bus is listed
        assert!(bus.active, Error_BusNotListed);  // Ensure bus is active
        assert!(bus.available_seats > 0, Error_Invalid_Seats);  // Ensure bus has available seats
        assert!(payment_coin.value() >= bus.price, Error_Insufficient_Payment);  // Ensure payment is sufficient

        bus.available_seats = bus.available_seats - 1;  // Decrease available seats
        let paid = split(payment_coin, bus.price, ctx);  // Split payment
        put(&mut bus.balance, paid);  // Add payment to bus balance

        let booked_seat_uid = new(ctx);  // Generate unique ID for booked seat
        let seat_number = bus.total_seats - bus.available_seats;  // Determine seat number
        transfer::transfer(BookedSeat {
            id: booked_seat_uid,
            bus_id: bus.bus_id,
            passenger: ctx.sender(),
        }, ctx.sender());

        event::emit(SeatBooked {
            bus_id: bus.bus_id,
            passenger: ctx.sender(),
            seat_number: seat_number,  // Emit seat number
        });

        if (bus.available_seats == 0) {  // If no seats available, unlist bus
            bus.active = false;
            event::emit(BusUnlisted {
                bus_id: bus.bus_id,
            });
        }
    }

    // Function to update details of a bus
    public fun update_bus_details(
        cap: &BusCap,  // Admin Capability
        bus: &mut Bus,  // Reference to the bus to update
        new_details: String,  // New bus details encoded as UTF-8 bytes
        _ctx: &mut TxContext  // Transaction context
    ) {
        assert!(object::id(bus) == cap.`for`, Error_NotOwner);
        bus.details = new_details;  // Update bus details

        event::emit(BusUpdated {
            bus_id: bus.bus_id,
            new_details: new_details,
        });
    }

    // Function to withdraw funds from a bus's balance
    public fun withdraw_funds(
        cap: &BusCap,  // Admin Capability
        bus: &mut Bus,  // Reference to the bus to withdraw funds from
        amount: u64,  // Amount to withdraw
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(object::id(bus) == cap.`for`, Error_NotOwner);
        assert!(amount <= bus.balance.value(), Error_Invalid_Amount);

        let remaining = take(&mut bus.balance, amount, ctx);  // Withdraw amount
        transfer::public_transfer(remaining, sender(ctx));  // Transfer withdrawn funds

        event::emit(FundWithdrawal {
            amount: amount,
            recipient: sender(ctx),
        });
    }

    // Function to create a driver profile
    public fun create_driver_profile(
        bus: ID,
        driver_name: String,  // Driver name encoded as UTF-8 bytes
        routes: vector<String>,  // Routes available for the driver
        ctx: &mut TxContext  // Transaction context
    ) {
        let driver_uid = new(ctx);  // Generate unique ID for driver profile

        let profile = DriverProfile {
            id: driver_uid,
            bus,
            rates: table::new(ctx),
            driver_name: driver_name,
            routes: routes,
        };

        transfer::share_object(profile);  // Store driver profile details
        event::emit(DriverProfileCreated {
            driver_id: object::id(&profile),
            driver_name: profile.driver_name.clone(),
        });
    }

    // Additional feature: Dynamic pricing based on seat availability
    public fun adjust_price_based_on_availability(
        bus: &mut Bus,  // Reference to the bus
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(bus.dynamic_pricing_enabled, Error_Invalid_Price);
        let initial_price = bus.price;

        if (bus.available_seats < bus.total_seats / 2) {
            bus.price = initial_price + (initial_price * 10 / 100);  // Increase price by 10% if less than half seats are available
        } else if (bus.available_seats == 1) {
            bus.price = initial_price + (initial_price * 20 / 100);  // Increase price by 20% if only one seat is left
        }

        event::emit(BusUpdated {
            bus_id: bus.bus_id,
            new_details: "Price adjusted based on seat availability.".to_string(),
        });
    }
}
