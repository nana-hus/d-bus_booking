#[allow(unused_use,unused_variable,lint(self_transfer),unused_field)]
module bus_booking::bus_booking{
    use sui::event;
    use sui::sui::SUI;
    use std::string::{String};
    use sui::coin::{Coin, value, split, put, take};
    use sui::object::new;
    use sui::balance::{Balance, zero, value as balance_value};
    use sui::tx_context::sender;
    use sui::table::{Self, Table};

    // Constants for error codes
    const Error_Invalid_Amount: u64 = 2;
    const Error_Insufficient_Payment: u64 = 4;
    const Error_Invalid_Price: u64 = 6;
    const Error_Invalid_Seats: u64 = 7;
    const Error_BusNotListed: u64 = 8;
    const Error_Not_Enrolled: u64 = 9;
    const Error_Not_owner: u64 = 0;


   // User struct definition
    public struct User has key {
        id: UID,
        `for`: ID,
        user_name: String,
        user_type: u8,
        public_key: String
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
    }

    public struct BusCap has key {
        id: UID,
        `for`: ID
    }

    // BookedSeat struct definition
    public struct BookedSeat has key {
        id: UID,
        bus_id: ID,
        passenger: address
    }

    // DriverProfile struct definition
    public struct DriverProfile has key {
        id: UID,
        driver_name: String,
        routes: vector<String>,
    }

    // DrivingService struct definition
    public struct DrivingService has key {
        id: UID,
        driver_id: u64,
        route_id: u64,
        rate: u64,
        available: bool,
    }

    // DrivingSession struct definition
    public struct DrivingSession has key {
        id: UID,
        driver_id: u64,
        passenger: address,
        session_id: u64,
        completed: bool,
        rating: u8,
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
        self: &mut Bus,
        user_name: String,  // Username encoded as UTF-8 bytes
        user_type: u8,          // Type of user (e.g., passenger, driver)
        public_key: String, // Public key of the user
        ctx: &mut TxContext     // Transaction context
    ) : User{
        // add sender to bus. 
        self.passengers.add(ctx.sender(), true);
        // create user object 
        User {  // Store user details
            id: new(ctx),
            `for`: object::id(self),
            user_name: user_name,
            user_type: user_type,
            public_key: public_key,
        }
    }

    // Function to create a new bus
    public fun create_bus(
        operator: address,       // Address of the bus operator
        name: String,       // Bus name encoded as UTF-8 bytes
        details: String,    // Bus details encoded as UTF-8 bytes
        price: u64,             // Price of a seat
        total_seats: u64,            // Total seats available
        ctx: &mut TxContext     // Transaction context
    ) {
        assert!(price > 0, Error_Invalid_Price);  // Validate price is positive
        assert!(total_seats > 0, Error_Invalid_Seats);  // Validate total seats are positive

        let bus_uid = new(ctx);  // Generate unique ID for the bus
        let inner = object::uid_to_inner(&bus_uid);
        let bus = Bus {  // Create new bus object
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
        };

        let cap = BusCap {
            id: new(ctx),
            `for`: inner
        };
        transfer::transfer(cap, sender(ctx));
        transfer::share_object(bus);  // Store bus details
        event::emit(BusCreated {  // Emit BusCreated event
            bus_id: inner,  // Placeholder for actual bus ID
            operator: operator,
        });
    }

    // Function to book a seat on a bus
    public fun book_seat(
        bus: &mut Bus,     // Reference to the bus to book a seat on
        payment_coin: &mut Coin<SUI>,  // Payment coin for booking
        ctx: &mut TxContext      // Transaction context
    ) {
        assert!(table::contains(&bus.passengers, ctx.sender()), Error_BusNotListed); // Ensure bus is listed
        assert!(bus.available_seats > 0, Error_Invalid_Seats);  // Ensure bus has available seats
        assert!(payment_coin.value() >= bus.price, Error_Insufficient_Payment);  // Ensure payment is sufficient
        let passenger = ctx.sender();
        let total_price = bus.price;  // Get total price of the seat

        bus.available_seats = bus.available_seats - 1;  // Decrease available seats
        let paid = split(payment_coin, total_price, ctx);  // Split payment
        put(&mut bus.balance, paid);  // Add payment to bus balance

        let booked_seat_uid = new(ctx);  // Generate unique ID for booked seat
        transfer::transfer(BookedSeat {  // Transfer booking details
            id: booked_seat_uid,
            bus_id: bus.bus_id,
            passenger: passenger,
        }, passenger);

        event::emit(SeatBooked {  // Emit SeatBooked event
            bus_id: bus.bus_id,
            passenger: passenger,
        });

        if (bus.available_seats == 0) {  // If no seats available, unlist bus
            event::emit(BusUnlisted {
                bus_id: bus.bus_id,
            });
        }
    }

    // Function to mark a bus as completed by a passenger
    public fun complete_bus(
        booked_seat: &BookedSeat,  // Reference to the booked seat
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(sender(ctx) == ctx.sender(), Error_Not_Enrolled);  // Ensure sender is booked passenger

        event::emit(BusCompleted {  // Emit BusCompleted event
            bus_id: booked_seat.bus_id,
            passenger: ctx.sender(),
        });
    }

    // Function to update details of a bus
    public fun update_bus_details(
        cap: &BusCap,          // Admin Capability
        bus: &mut Bus,     // Reference to the bus to update
        new_details: String, // New bus details encoded as UTF-8 bytes
        _ctx: &mut TxContext     // Transaction context
    ) {
        assert!(object::id(bus) == cap.`for`, Error_Not_owner);
        let details_str = new_details;  // Convert bytes to string
        bus.details = details_str;  // Update bus details

        event::emit(BusUpdated {  // Emit BusUpdated event
            bus_id: bus.bus_id,
            new_details: details_str,
        });
    }

    // Function to withdraw funds from a bus's balance
    public fun withdraw_funds(
        cap: &BusCap,          // Admin Capability
        bus: &mut Bus,     // Reference to the bus to withdraw funds from
        amount: u64,       // Amount to withdraw
        ctx: &mut TxContext     // Transaction context
    ) {
        assert!(object::id(bus) == cap.`for`, Error_Not_owner);
        let value = bus.balance.value();
        assert!(value >= amount, Error_Invalid_Amount);  // Ensure sufficient balance
        let remaining = take(&mut bus.balance, amount, ctx);  // Withdraw amount

        transfer::public_transfer(remaining, sender(ctx));  // Transfer withdrawn funds
        event::emit(FundWithdrawal {  // Emit FundWithdrawal event
            amount: amount,
            recipient: sender(ctx),
        });
    }

    // Function to create a driver profile
    public fun create_driver_profile(
        driver_name: String,  // Driver name encoded as UTF-8 bytes
        routes: vector<String>, // Routes available for the driver
        ctx: &mut TxContext,  // Transaction context
    ) {
        let driver_uid = new(ctx);  // Generate unique ID for driver profile
        let driver_id = 0;

        let profile = DriverProfile {  // Create new driver profile object
            id: driver_uid,
            driver_name: driver_name,
            routes: routes,
        };

        transfer::share_object(profile);  // Store driver profile details
        event::emit(DriverProfileCreated {  // Emit DriverProfileCreated event
            driver_id: driver_id,
            driver_name: driver_name,
        });
    }

    // Function to offer a driving service
    public fun offer_driving_service(
        driver_id: u64, // Driver ID
        route_id: u64,  // Route ID
        rate: u64,  // Rate per session
        ctx: &mut TxContext  // Transaction context
    ) {
        let service_id = new(ctx);  // Generate unique ID for driving service

        let service = DrivingService {  // Create new driving service object
            id: service_id,
            driver_id: driver_id,
            route_id: route_id,
            rate: rate,
            available: true,
        };

        transfer::share_object(service);  // Store driving service details
        event::emit(DrivingServiceOffered {  // Emit DrivingServiceOffered event
            driver_id: driver_id,
            route_id: route_id,
            rate: rate,
        });
    }

    // Function to complete a driving session
    public fun complete_driving_session(
        session: &mut DrivingSession,  // Reference to the driving session
        rating: u8,  // Rating for the session
        ctx: &mut TxContext  // Transaction context
    ) {
        assert!(session.passenger == ctx.sender(), Error_Not_Enrolled);  // Ensure sender is the passenger
        session.completed = true;  // Mark session as completed
        session.rating = rating;  // Set rating for the session

        event::emit(DrivingSessionCompleted {  // Emit DrivingSessionCompleted event
            session_id: session.session_id,
            driver_id: session.driver_id,
            passenger: session.passenger,
        });
    }

    // Function to update a driving service
    public fun update_driving_service(
        driver_id: u64, // Driver ID
        route_id: u64,  // Route ID
        rate: u64,  // Updated rate per session
        available: bool,  // Updated availability status
        ctx: &mut TxContext  // Transaction context
    ) {
        let service = DrivingService {
            id: new(ctx),
            driver_id: driver_id,
            route_id: route_id,
            rate: rate,
            available: available,
        };

        transfer::share_object(service);  // Store updated driving service details
        event::emit(DrivingServiceUpdated {  // Emit DrivingServiceUpdated event
            driver_id: driver_id,
            route_id: route_id,
            rate: rate,
            available: available,
        });
    }
}
