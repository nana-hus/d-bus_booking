# Bus Booking Module

The `bus_booking` module is designed to manage a decentralized bus booking system on the Sui blockchain. This module allows users to register, create buses, book seats, manage bus details, and handle driver profiles and driving services.

## Features

- **User Registration:** Register users with unique IDs, usernames, user types, and public keys.
- **Bus Management:** Create, update, and manage buses with unique IDs, names, details, prices, and available seats.
- **Seat Booking:** Book seats on buses and handle payments securely.
- **Event Emission:** Emit events for bus creation, seat booking, bus updates, and more.
- **Driver Profiles:** Create and manage driver profiles with routes.
- **Driving Services:** Offer and update driving services with specific routes and rates.
- **Driving Sessions:** Manage driving sessions, including completion and rating.

## Structs

### User

- `id`: Unique identifier for the user.
- `for`: Identifier of the associated entity.
- `user_name`: Username.
- `user_type`: Type of user (e.g., passenger, driver).
- `public_key`: Public key of the user.

### Bus

- `id`: Unique identifier for the bus.
- `bus_id`: Bus ID.
- `passengers`: Table to store passengers.
- `name`: Name of the bus.
- `details`: Details of the bus.
- `price`: Price per seat.
- `total_seats`: Total number of seats.
- `available_seats`: Number of available seats.
- `operator`: Address of the bus operator.
- `balance`: Balance for the bus.

### BusCap

- `id`: Unique identifier for the capability.
- `for`: Identifier of the associated bus.

### BookedSeat

- `id`: Unique identifier for the booked seat.
- `bus_id`: Identifier of the associated bus.
- `passenger`: Address of the passenger.

### DriverProfile

- `id`: Unique identifier for the driver profile.
- `driver_name`: Name of the driver.
- `routes`: Routes available for the driver.

### DrivingService

- `id`: Unique identifier for the driving service.
- `driver_id`: Identifier of the driver.
- `route_id`: Identifier of the route.
- `rate`: Rate per session.
- `available`: Availability status of the service.

### DrivingSession

- `id`: Unique identifier for the driving session.
- `driver_id`: Identifier of the driver.
- `passenger`: Address of the passenger.
- `session_id`: Identifier of the session.
- `completed`: Completion status of the session.
- `rating`: Rating for the session.

## Events

- `BusCreated`: Emitted when a new bus is created.
- `SeatBooked`: Emitted when a seat is booked.
- `BusCompleted`: Emitted when a bus is marked as completed.
- `BusUpdated`: Emitted when a bus's details are updated.
- `BusUnlisted`: Emitted when a bus is unlisted.
- `FundWithdrawal`: Emitted when funds are withdrawn from a bus's balance.
- `DriverProfileCreated`: Emitted when a driver profile is created.
- `DrivingServiceOffered`: Emitted when a driving service is offered.
- `DrivingSessionRequested`: Emitted when a driving session is requested.
- `DrivingSessionCompleted`: Emitted when a driving session is completed.
- `DrivingServiceUpdated`: Emitted when a driving service is updated.

## Functions

### `register_user`

Register a new user.

### `create_bus`

Create a new bus.

### `book_seat`

Book a seat on a bus.

### `complete_bus`

Mark a bus as completed by a passenger.

### `update_bus_details`

Update details of a bus.

### `withdraw_funds`

Withdraw funds from a bus's balance.

### `create_driver_profile`

Create a driver profile.

### `offer_driving_service`

Offer a driving service.

### `complete_driving_session`

Complete a driving session.

### `update_driving_service`

Update a driving service.

## Error Codes

- `Error_Invalid_Amount`: Invalid amount.
- `Error_Insufficient_Payment`: Insufficient payment.
- `Error_Invalid_Price`: Invalid price.
- `Error_Invalid_Seats`: Invalid seats.
- `Error_BusNotListed`: Bus not listed.
- `Error_Not_Enrolled`: Not enrolled.
- `Error_Not_owner`: Not the owner.

## Usage

1. **Register Users:** Use `register_user` to register new users.
2. **Create Buses:** Use `create_bus` to create new buses.
3. **Book Seats:** Use `book_seat` to book seats on available buses.
4. **Complete Buses:** Use `complete_bus` to mark buses as completed.
5. **Manage Buses:** Use `update_bus_details` and `withdraw_funds` to manage buses.
6. **Driver Profiles:** Use `create_driver_profile` to create driver profiles.
7. **Driving Services:** Use `offer_driving_service` and `update_driving_service` to manage driving services.
8. **Driving Sessions:** Use `complete_driving_session` to complete driving sessions.

## Contributing

Please feel free to contribute by opening issues, submitting pull requests, or suggesting improvements.

## License

This project is licensed under the MIT License.

---

This README provides an overview of the `bus_booking` module, its features, and usage instructions. If you need more details or further customization, let me know!# d-bus_booking
